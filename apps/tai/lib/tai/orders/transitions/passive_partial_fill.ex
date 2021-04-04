defmodule Tai.Orders.Transitions.PassivePartialFill do
  @moduledoc """
  An open order has been partially filled
  """

  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %__MODULE__{
          client_id: client_id,
          cumulative_qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          last_received_at: integer,
          last_venue_timestamp: DateTime.t()
        }

  @enforce_keys ~w[client_id cumulative_qty leaves_qty last_received_at last_venue_timestamp]a
  defstruct ~w[client_id cumulative_qty leaves_qty last_received_at last_venue_timestamp]a

  defimpl Tai.Orders.Transition do
    @required ~w(open partially_filled pending_amend pending_cancel amend_error cancel_accepted cancel_error)a
    def required(_), do: @required

    def attrs(transition) do
      {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(transition.last_received_at)

      %{
        status: :partially_filled,
        cumulative_qty: transition.cumulative_qty,
        leaves_qty: transition.leaves_qty,
        qty: Decimal.add(transition.cumulative_qty, transition.leaves_qty),
        last_received_at: last_received_at,
        last_venue_timestamp: transition.last_venue_timestamp
      }
    end
  end
end
