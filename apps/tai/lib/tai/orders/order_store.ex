defmodule Tai.Orders.OrderStore do
  @moduledoc """
  Track and manage the local state of orders with a swappable backend
  """

  use GenServer

  alias Tai.Orders.{
    Order,
    Submissions,
    Transition,
    Transitions
  }

  @type submission :: Submissions.Factory.submission()
  @type order :: Order.t()
  @type status :: Order.status()
  @type client_id :: Order.client_id()
  @type transition :: Transition.t()
  @type store_id :: atom

  @default_id :default
  @default_backend Tai.Orders.OrderStore.Backends.ETS

  defmodule State do
    @type t :: %State{id: atom, name: atom, backend: module}
    defstruct ~w(id name backend)a
  end

  def start_link(args) do
    id = Keyword.get(args, :id, @default_id)
    backend = Keyword.get(args, :backend, @default_backend)
    name = :"#{__MODULE__}_#{id}"
    state = %State{id: id, name: name, backend: backend}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  def init(state), do: {:ok, state, {:continue, :init}}

  def handle_continue(:init, state) do
    :ok = state.backend.create(state.name)
    {:noreply, state}
  end

  def handle_call({:enqueue, submission}, _from, state) do
    order = Submissions.Factory.build!(submission)
    response = state.backend.insert(order, state.name)
    {:reply, response, state}
  end

  def handle_call({:update, transition}, _from, state) do
    response =
      with {:ok, old_order} <- state.backend.find_by_client_id(transition.client_id, state.name) do
        required = transition |> Transition.required() |> List.wrap()

        if Enum.member?(required, old_order.status) do
          new_attrs =
            transition
            |> Transition.attrs()
            |> normalize_attrs(old_order, transition)
            |> Map.put(:updated_at, Timex.now())

          updated_order = old_order |> Map.merge(new_attrs)
          state.backend.update(updated_order, state.name)
          {:ok, {old_order, updated_order}}
        else
          reason = {:invalid_status, old_order.status, required |> format_required, transition}
          {:error, reason}
        end
      else
        {:error, :not_found} -> {:error, {:not_found, transition}}
      end

    {:reply, response, state}
  end

  def handle_call(:all, _from, state) do
    response = state.backend.all(state.name)
    {:reply, response, state}
  end

  def handle_call({:find_by_client_id, client_id}, _from, state) do
    response = state.backend.find_by_client_id(client_id, state.name)
    {:reply, response, state}
  end

  @doc """
  Enqueue an order from the submission by adding it into the backend
  """
  @spec enqueue(submission) :: {:ok, order} | no_return
  def enqueue(submission, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:enqueue, submission})
  end

  @doc """
  Update the state of the order from the transitions params
  """
  @spec update(transition) ::
          {:ok, {old :: order, updated :: order}}
          | {:error,
             {:not_found, transition}
             | {:invalid_status, current :: status, required :: [status], transition}}
  def update(transition, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:update, transition})
  end

  @doc """
  Return a list of all orders currently stored in the backend
  """
  @spec all :: [] | [order]
  def all(store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call(:all)
  end

  @doc """
  Return the number of orders currently stored in the backend
  """
  @spec count :: non_neg_integer
  def count(store_id \\ @default_id), do: store_id |> all() |> Enum.count()

  @doc """
  Return the order from the backend that matches the given client_id
  """
  @spec find_by_client_id(client_id) :: {:ok, order} | {:error, :not_found}
  def find_by_client_id(client_id, store_id \\ @default_id) do
    store_id
    |> to_name
    |> GenServer.call({:find_by_client_id, client_id})
  end

  @spec to_name(store_id) :: atom
  def to_name(store_id), do: :"#{__MODULE__}_#{store_id}"

  defp normalize_attrs(
         update_attrs,
         %Order{cumulative_qty: cumulative_qty},
         %Transitions.Amend{leaves_qty: leaves_qty}
       ) do
    qty = Decimal.add(cumulative_qty, leaves_qty)
    update_attrs |> Map.put(:qty, qty)
  end

  defp normalize_attrs(
         update_attrs,
         %Order{cumulative_qty: cumulative_qty},
         %Transitions.Cancel{}
       ) do
    update_attrs |> Map.put(:qty, cumulative_qty)
  end

  defp normalize_attrs(update_attrs, _, _), do: update_attrs

  defp format_required([required | []]), do: required
  defp format_required(required), do: required
end
