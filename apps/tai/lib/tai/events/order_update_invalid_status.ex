defmodule Tai.Events.OrderUpdateInvalidStatus do
  alias __MODULE__

  @type status :: Tai.Orders.Order.status()
  @type client_id :: Tai.Orders.Order.client_id()
  @type t :: %OrderUpdateInvalidStatus{
          client_id: client_id,
          transition: atom | module,
          was: status,
          required: status | [status],
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil
        }

  @enforce_keys ~w[
    client_id
    transition
    was
    required
  ]a
  defstruct ~w[
    client_id
    transition
    was
    required
    last_received_at
    last_venue_timestamp
  ]a
end

defimpl TaiEvents.LogEvent, for: Tai.Events.OrderUpdateInvalidStatus do
  def to_data(event) do
    keys =
      event
      |> Map.keys()
      |> Enum.filter(&(&1 != :__struct__))

    event
    |> Map.take(keys)
    |> Map.put(
      :last_received_at,
      event.last_received_at && event.last_received_at |> DateTime.to_iso8601()
    )
    |> Map.put(
      :last_venue_timestamp,
      event.last_venue_timestamp && event.last_venue_timestamp |> DateTime.to_iso8601()
    )
  end
end
