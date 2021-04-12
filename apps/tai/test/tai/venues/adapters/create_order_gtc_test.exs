defmodule Tai.Venues.Adapters.CreateOrderGtcTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  setup_all do
    on_exit(fn ->
      :ok = Application.stop(:tai_events)
      :ok = Application.stop(:tai)
    end)

    {:ok, _} = Application.ensure_all_started(:tai)
    HTTPoison.start()
  end

  @sides [:buy, :sell]

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_gtc_open()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      test "#{venue.id} #{side} limit filled open" do
        order = build_order(@venue.id, @side, :gtc, post_only: false, action: :filled)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_gtc_filled" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

          assert order_response.id != nil
          assert %Decimal{} = order_response.original_size
          assert %Decimal{} = order_response.cumulative_qty
          assert order_response.leaves_qty == Decimal.new(0)
          assert order_response.cumulative_qty == order_response.original_size
          assert order_response.status == :filled
          assert %DateTime{} = order_response.venue_timestamp
          assert order_response.received_at != nil
        end
      end

      test "#{venue.id} #{side} limit partially filled open" do
        order = build_order(@venue.id, @side, :gtc, post_only: false, action: :partially_filled)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_gtc_partially_filled" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

          assert order_response.id != nil
          assert %Decimal{} = order_response.original_size
          assert %Decimal{} = order_response.leaves_qty
          assert order_response.cumulative_qty != order_response.original_size
          assert order_response.cumulative_qty != Decimal.new(0)
          assert order_response.leaves_qty != Decimal.new(0)
          assert order_response.leaves_qty != order_response.original_size
          assert order_response.status == :open
          assert %DateTime{} = order_response.venue_timestamp
          assert order_response.received_at != nil
        end
      end

      test "#{venue.id} #{side} limit unfilled open" do
        order = build_order(@venue.id, @side, :gtc, post_only: false, action: :unfilled)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_gtc_unfilled" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

          assert order_response.id != nil
          assert order_response.status == :open
          assert order_response.leaves_qty == order_response.original_size
          assert order_response.cumulative_qty == Decimal.new(0)
          assert %DateTime{} = order_response.venue_timestamp
          assert order_response.received_at != nil
        end
      end
    end)
  end)

  Tai.TestSupport.Helpers.test_venue_adapters_create_order_gtc_accepted()
  |> Enum.map(fn venue ->
    @venue venue

    setup do
      {:ok, _} = Tai.Venues.VenueStore.put(@venue)
      :ok
    end

    @sides
    |> Enum.each(fn side ->
      @side side

      test "#{venue.id} #{side} limit unfilled accepted" do
        order = build_order(@venue.id, @side, :gtc, post_only: false, action: :unfilled)

        use_cassette "venue_adapters/shared/orders/#{@venue.id}/#{@side}_limit_gtc_unfilled" do
          assert {:ok, order_response} = Tai.Venues.Client.create_order(order)

          assert %Tai.Trading.OrderResponses.CreateAccepted{} = order_response
          assert order_response.id != nil
          assert order_response.received_at != nil
        end
      end
    end)
  end)

  defp build_order(venue_id, side, time_in_force, opts) do
    action = Keyword.fetch!(opts, :action)
    post_only = Keyword.get(opts, :post_only, false)

    struct(Tai.Trading.Order, %{
      client_id: Ecto.UUID.generate(),
      venue_id: venue_id,
      credential_id: :main,
      venue_product_symbol: venue_id |> venue_product_symbol,
      product_symbol: venue_id |> product_symbol,
      product_type: venue_id |> product_type,
      side: side,
      price: venue_id |> price(side, time_in_force, action),
      qty: venue_id |> qty(side, time_in_force, action),
      type: :limit,
      time_in_force: time_in_force,
      post_only: post_only
    })
  end

  defp venue_product_symbol(:bitmex), do: "XBTH19"
  defp venue_product_symbol(:okex_futures), do: "ETH-USD-190628"
  defp venue_product_symbol(:okex_swap), do: "ETH-USD-SWAP"
  defp venue_product_symbol(:okex_spot), do: "ETH-USDT"
  defp venue_product_symbol(:ftx), do: "BTC/USD"
  defp venue_product_symbol(_), do: "LTC-BTC"

  defp product_symbol(:bitmex), do: :xbth19
  defp product_symbol(:okex_futures), do: :eth_usd_190628
  defp product_symbol(:okex_swap), do: :eth_usd_swap
  defp product_symbol(:okex_spot), do: :eth_usdt
  defp product_symbol(:ftx), do: :"btc/usd"
  defp product_symbol(_), do: :ltc_btc

  defp product_type(:okex_swap), do: :swap
  defp product_type(:okex_spot), do: :spot
  defp product_type(_), do: :future

  defp price(:bitmex, :buy, :gtc, :filled), do: Decimal.new("4455")
  defp price(:bitmex, :sell, :gtc, :filled), do: Decimal.new("3767")
  defp price(:bitmex, :buy, :gtc, :unfilled), do: Decimal.new("100.5")
  defp price(:bitmex, :sell, :gtc, :unfilled), do: Decimal.new("50000.5")
  defp price(:okex_futures, :buy, :gtc, :unfilled), do: Decimal.new("70.5")
  defp price(:okex_futures, :sell, :gtc, :unfilled), do: Decimal.new("290.5")
  defp price(:okex_swap, :buy, :gtc, :unfilled), do: Decimal.new("70.5")
  defp price(:okex_swap, :sell, :gtc, :unfilled), do: Decimal.new("290.5")
  defp price(:okex_spot, :buy, :gtc, :unfilled), do: Decimal.new("70.5")
  defp price(:okex_spot, :sell, :gtc, :unfilled), do: Decimal.new("290.5")
  defp price(:ftx, :buy, :gtc, :unfilled), do: Decimal.new("25000.5")
  defp price(:ftx, :sell, :gtc, :unfilled), do: Decimal.new("75000.5")
  defp price(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new("4130")
  defp price(:bitmex, :sell, :gtc, :partially_filled), do: Decimal.new("3795.5")
  defp price(_, :buy, _, _), do: Decimal.new("0.007")
  defp price(_, :sell, _, _), do: Decimal.new("0.1")

  defp qty(:bitmex, :buy, :gtc, :filled), do: Decimal.new(150)
  defp qty(:bitmex, :sell, :gtc, :filled), do: Decimal.new(10)
  defp qty(:bitmex, :buy, :gtc, :partially_filled), do: Decimal.new(100)
  defp qty(:bitmex, :sell, :gtc, :partially_filled), do: Decimal.new(100)
  defp qty(:bitmex, _, :gtc, :insufficient_balance), do: Decimal.new(1_000_000)
  defp qty(:bitmex, :buy, _, _), do: Decimal.new(1)
  defp qty(:bitmex, :sell, _, _), do: Decimal.new(1)
  defp qty(:okex_futures, :buy, _, _), do: Decimal.new(1)
  defp qty(:okex_futures, :sell, _, _), do: Decimal.new(1)
  defp qty(:okex_swap, :buy, _, _), do: Decimal.new(1)
  defp qty(:okex_swap, :sell, _, _), do: Decimal.new(1)
  defp qty(:okex_spot, :buy, _, _), do: Decimal.new(1)
  defp qty(:okex_spot, :sell, _, _), do: Decimal.new(1)
  defp qty(:ftx, :buy, :gtc, :unfilled), do: Decimal.new("0.0001")
  defp qty(:ftx, :sell, :gtc, :unfilled), do: Decimal.new("0.0001")
  defp qty(_, _, :gtc, :insufficient_balance), do: Decimal.new(1_000)
  defp qty(_, :buy, _, _), do: Decimal.new("0.2")
  defp qty(_, :sell, _, _), do: Decimal.new("0.1")
end
