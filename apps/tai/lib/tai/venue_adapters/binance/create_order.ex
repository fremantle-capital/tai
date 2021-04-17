defmodule Tai.VenueAdapters.Binance.CreateOrder do
  @moduledoc """
  Create orders for the Binance adapter
  """

  alias Tai.VenueAdapters.Binance.OrderStatus
  alias Tai.Orders

  @limit "LIMIT"

  def create_order(%Tai.Orders.Order{side: side, type: :limit} = order, credentials) do
    venue_time_in_force = order.time_in_force |> to_venue_time_in_force
    venue_side = side |> Atom.to_string() |> String.upcase()
    credentials = struct!(ExBinance.Credentials, credentials)

    order.venue_product_symbol
    |> ExBinance.Private.create_order(
      venue_side,
      @limit,
      order.qty,
      order.price,
      venue_time_in_force,
      credentials
    )
    |> parse_response(order)
  end

  defp to_venue_time_in_force(:gtc), do: "GTC"
  defp to_venue_time_in_force(:fok), do: "FOK"
  defp to_venue_time_in_force(:ioc), do: "IOC"

  defp leaves_qty(:filled, _, _), do: Decimal.new(0)
  defp leaves_qty(:expired, _, _), do: Decimal.new(0)
  defp leaves_qty(:open, orig_qty, cum_qty), do: orig_qty |> Decimal.sub(cum_qty)

  defp parse_response({:ok, %ExBinance.Responses.CreateOrder{} = binance_response}, _) do
    received_at = Tai.Time.monotonic_time()
    venue_order_id = binance_response.order_id |> Integer.to_string()
    status = binance_response.status |> OrderStatus.from_venue()
    original_size = binance_response.orig_qty |> Decimal.new() |> Decimal.normalize()
    cumulative_qty = binance_response.executed_qty |> Decimal.new() |> Decimal.normalize()
    leaves_qty = leaves_qty(status, original_size, cumulative_qty)
    venue_timestamp = binance_response.transact_time |> DateTime.from_unix!(:millisecond)

    response = %Orders.Responses.Create{
      id: venue_order_id,
      status: status,
      original_size: original_size,
      leaves_qty: leaves_qty,
      cumulative_qty: cumulative_qty,
      venue_timestamp: venue_timestamp,
      received_at: received_at
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout} = error, _), do: error
  defp parse_response({:error, :connect_timeout} = error, _), do: error

  defp parse_response({:error, {:insufficient_balance, _}}, _),
    do: {:error, :insufficient_balance}

  defp parse_response({:error, reason}, _), do: {:error, {:unhandled, reason}}
end
