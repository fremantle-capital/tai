defmodule ExamplesSupport.E2E.PingPong do
  alias Tai.TestSupport.Mocks
  import Tai.TestSupport.Mock

  @venue :test_exchange_a
  @credential :main
  @venue_product "BTC-USD"
  @product :btc_usd
  @product_type :swap
  @price_increment Decimal.new("0.5")
  @entry_venue_order_id_1 "entryOrderA"
  @entry_venue_order_id_2 "entryOrderB"
  @exit_venue_order_id "exitOrder"

  def seed_mock_responses(:ping_pong) do
    Mocks.Responses.Products.for_venue(@venue, [
      %{symbol: @product, type: @product_type, price_increment: @price_increment}
    ])

    Tai.TestSupport.Mocks.Responses.Accounts.for_venue_and_credential(
      @venue,
      @credential,
      [
        %{
          asset: :btc,
          equity: Decimal.new("0.3"),
          free: Decimal.new("0.1"),
          locked: Decimal.new("0.2")
        },
        %{
          asset: :usd,
          equity: Decimal.new("10000"),
          free: Decimal.new("10000"),
          locked: Decimal.new("0")
        }
      ]
    )

    Mocks.Responses.MakerTakerFees.for_venue_and_credential(
      @venue,
      @credential,
      {Decimal.new("0.0005"), Decimal.new("0.0005")}
    )

    Mocks.Responses.Orders.GoodTillCancel.open(
      @entry_venue_order_id_1,
      %Tai.Orders.OrderSubmissions.BuyLimitGtc{
        venue_id: @venue,
        credential_id: @credential,
        venue_product_symbol: @venue_product,
        product_symbol: @product,
        product_type: @product_type,
        price: Decimal.new("5500.5"),
        qty: Decimal.new(10),
        post_only: true
      }
    )

    Mocks.Responses.Orders.GoodTillCancel.canceled(@entry_venue_order_id_1)

    Mocks.Responses.Orders.GoodTillCancel.open(
      @entry_venue_order_id_2,
      %Tai.Orders.OrderSubmissions.BuyLimitGtc{
        venue_id: @venue,
        credential_id: @credential,
        venue_product_symbol: @venue_product,
        product_symbol: @product,
        product_type: @product_type,
        price: Decimal.new("5504.0"),
        qty: Decimal.new(10),
        post_only: true
      }
    )
  end

  def seed_venues(:ping_pong) do
    {:ok, _} =
      Tai.Venue
      |> struct(
        id: @venue,
        adapter: Tai.VenueAdapters.Mock,
        credentials: Map.put(%{}, @credential, %{}),
        accounts: "*",
        products: "*",
        quote_depth: 1,
        timeout: 1000
      )
      |> Tai.Venues.VenueStore.put()
  end

  def push_stream_market_data({:ping_pong, :snapshot, venue_id, product_symbol})
      when venue_id == @venue and product_symbol == @product do
    push_market_data_snapshot(
      %Tai.Markets.Location{
        venue_id: @venue,
        product_symbol: @product
      },
      %{5500 => 101},
      %{5501 => 202}
    )
  end

  def push_stream_market_data({:ping_pong, :change_1, venue_id, product_symbol})
      when venue_id == @venue and product_symbol == @product do
    push_market_data_snapshot(
      %Tai.Markets.Location{
        venue_id: @venue,
        product_symbol: @product
      },
      %{5504 => 20},
      %{5504.5 => 17}
    )
  end

  def push_stream_order_update(
        {:ping_pong, :order_update_filled, venue_id, product_symbol},
        client_id
      )
      when venue_id == @venue and product_symbol == @product do
    submission = %Tai.Orders.OrderSubmissions.SellLimitGtc{
      venue_id: @venue,
      credential_id: @credential,
      venue_product_symbol: @venue_product,
      product_symbol: @product,
      product_type: @product_type,
      post_only: true,
      price: Decimal.new("5504.5"),
      qty: Decimal.new(10)
    }

    Tai.TestSupport.Mocks.Responses.Orders.GoodTillCancel.open(@exit_venue_order_id, submission)

    @venue
    |> push_order_update(%{
      client_id: client_id,
      status: :filled,
      cumulative_qty: 10,
      leaves_qty: 0
    })
  end

  def advisor_group_config(:ping_pong) do
    [
      advisor: Examples.PingPong.Advisor,
      factory: Tai.Advisors.Factories.OnePerProduct,
      products: "test_exchange_a.btc_usd",
      config:
        {Examples.PingPong.Config,
         %{
           product: {{@venue, @product}, :product},
           fee: {{@venue, @product, @credential}, :fee},
           max_qty: {10, :decimal}
         }}
    ]
  end
end
