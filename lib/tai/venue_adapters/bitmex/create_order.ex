defmodule Tai.VenueAdapters.Bitmex.CreateOrder do
  @moduledoc """
  Create orders for the Bitmex adapter
  """

  def create_order(%Tai.Trading.Order{} = order, credentials) do
    params = build_params(order)

    credentials
    |> to_bitmex_credentials
    |> ExBitmex.Rest.Orders.create(params)
    |> parse_response(order)
  end

  defp build_params(order) do
    params = %{
      side: order.side |> to_venue_side,
      ordType: "Limit",
      symbol: order.symbol |> to_venue_symbol,
      orderQty: order.qty,
      price: order.price,
      timeInForce: order.time_in_force |> to_venue_time_in_force
    }

    if order.post_only do
      Map.put(params, "execInst", "ParticipateDoNotInitiate")
    else
      params
    end
  end

  defp to_bitmex_credentials(%{api_key: api_key, api_secret: api_secret}) do
    %ExBitmex.Credentials{api_key: api_key, api_secret: api_secret}
  end

  defp to_venue_side(:buy), do: "Buy"
  defp to_venue_side(:sell), do: "Sell"

  defp to_venue_symbol(symbol) do
    symbol
    |> Atom.to_string()
    |> String.upcase()
  end

  defp to_venue_time_in_force(:gtc), do: "GoodTillCancel"
  defp to_venue_time_in_force(:ioc), do: "ImmediateOrCancel"
  defp to_venue_time_in_force(:fok), do: "FillOrKill"

  defp parse_response(
         {:ok, %ExBitmex.Order{} = venue_order, %ExBitmex.RateLimit{}},
         order
       ) do
    response = %Tai.Trading.OrderResponse{
      id: venue_order.order_id,
      status: venue_order.ord_status |> from_venue_status(order),
      time_in_force: order.time_in_force,
      original_size: Decimal.new(venue_order.order_qty),
      cumulative_qty: Decimal.new(venue_order.cum_qty)
    }

    {:ok, response}
  end

  defp parse_response({:error, :timeout, nil}, _) do
    {:error, :timeout}
  end

  defp parse_response({:error, {:insufficient_balance, _msg}, _}, _) do
    {:error, :insufficient_balance}
  end

  defp from_venue_status("New", _), do: :open
  defp from_venue_status("PartiallyFilled", _), do: :open
  defp from_venue_status("Filled", _), do: :filled
  # https://www.bitmex.com/app/apiChangelog#Jul-5-2016
  defp from_venue_status("Canceled", %Tai.Trading.Order{time_in_force: :gtc, post_only: true}),
    do: :rejected

  defp from_venue_status("Canceled", %Tai.Trading.Order{time_in_force: :ioc}), do: :expired
  defp from_venue_status("Canceled", %Tai.Trading.Order{time_in_force: :fok}), do: :expired
  defp from_venue_status("Canceled", _), do: :canceled
  # TODO: Unhandled Bitmex order status
  # defp from_venue_status("PendingNew"), do: :pending
  # defp from_venue_status("DoneForDay"), do: :open
  # defp from_venue_status("Stopped"), do: :open
  # defp from_venue_status("PendingCancel"), do: :canceling
  # defp from_venue_status("Expired"), do: :expired
end
