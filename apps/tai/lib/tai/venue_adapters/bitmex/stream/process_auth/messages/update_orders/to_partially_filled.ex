defmodule Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled do
  defstruct ~w(
    account
    cl_ord_id
    leaves_qty
    ord_status
    order_id
    cum_qty
    price
    symbol
    text
    timestamp
    transact_time
    working_indicator
  )a
end

defimpl Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Message,
  for: Tai.VenueAdapters.Bitmex.Stream.ProcessAuth.Messages.UpdateOrders.ToPartiallyFilled do
  alias Tai.VenueAdapters.Bitmex

  @date_format "{ISO:Extended}"

  def process(message, received_at, _state) do
    message.cl_ord_id
    |> case do
      "gtc-" <> id ->
        client_id = Bitmex.ClientId.from_base64(id)
        venue_timestamp = message.timestamp |> Timex.parse!(@date_format)
        leaves_qty = message.leaves_qty |> Tai.Utils.Decimal.cast!()
        cumulative_qty = message.cum_qty |> Tai.Utils.Decimal.cast!()

        %Tai.Orders.Transitions.PassivePartialFill{
          client_id: client_id,
          cumulative_qty: cumulative_qty,
          leaves_qty: leaves_qty,
          last_received_at: received_at,
          last_venue_timestamp: venue_timestamp
        }
        |> Tai.Orders.OrderStore.update()
        |> notify()

      _ ->
        :ignore
    end

    :ok
  end

  defp notify({:ok, {old, updated}}) do
    Tai.Orders.Services.NotifyUpdate.notify!(old, updated)
  end

  defp notify({:error, {:invalid_status, was, required, %transition_name{} = transition}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateInvalidStatus{
      client_id: transition.client_id,
      transition: transition_name,
      was: was,
      required: required,
      last_received_at: transition.last_received_at,
      last_venue_timestamp: transition.last_venue_timestamp
    })
  end

  defp notify({:error, {:not_found, %transition_name{} = transition}}) do
    TaiEvents.warn(%Tai.Events.OrderUpdateNotFound{
      client_id: transition.client_id,
      transition: transition_name
    })
  end
end
