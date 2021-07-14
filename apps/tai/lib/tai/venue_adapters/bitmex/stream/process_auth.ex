defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth do
  use GenServer
  alias Tai.VenueAdapters.Bitmex.Stream

  defmodule State do
    @type venue_id :: Tai.Venue.id()
    @type credential_id :: Tai.Venue.credential_id()
    @type t :: %State{
            venue: venue_id,
            credential_id: credential_id
          }

    @enforce_keys ~w[venue credential_id]a
    defstruct ~w[venue credential_id]a
  end

  @type venue_id :: Tai.Venue.id()
  @type credential :: Tai.Venue.credential()

  @spec start_link(venue: venue_id, credential: credential) :: GenServer.on_start()
  def start_link(venue: venue, credential: {credential_id, _}) do
    state = %State{venue: venue, credential_id: credential_id}
    name = process_name(venue)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @spec process_name(venue_id) :: atom
  def process_name(venue), do: :"#{__MODULE__}_#{venue}"

  @deprecated "Use Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.process_name/1 instead."
  @spec to_name(venue_id) :: atom
  def to_name(venue), do: :"#{__MODULE__}_#{venue}"

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({%{"table" => "order", "action" => action, "data" => data}, received_at}, state) do
    case action do
      "update" -> Enum.each(data, & Stream.UpdateOrder.apply(&1, received_at, state))
      _ -> nil
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({msg, received_at}, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()

    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: last_received_at
    })

    {:noreply, state}
  end

  # TODO: Need to handle and test all the venue messages
  # @impl true
  # def handle_cast({%{"table" => "margin", "action" => action, "data" => data}, received_at}, state) do
  #   {:noreply, state}
  # end

  # @impl true
  # def handle_cast({%{"table" => "position", "action" => action, "data" => data}, received_at}, state) do
  #   {:noreply, state}
  # end

  # @impl true
  # def handle_cast({venue_msg, received_at}, state) do
  #   venue_msg
  #   |> extract()
  #   |> process(received_at, state)

  #   {:noreply, state}
  # end

  # def extract(msg) do
  #   Stream.ProcessAuth.VenueMessage.extract(msg)
  # end

  # defp process(messages, received_at, state) do
  #   messages
  #   |> Enum.map(&Stream.ProcessAuth.Message.process(&1, received_at, state))
  # end
end
