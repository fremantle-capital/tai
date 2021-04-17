defmodule Examples.PingPong.CreateEntryOrder do
  alias Examples.PingPong.{Config, EntryPrice}
  alias Tai.Orders.OrderSubmissions

  @type advisor_process :: Tai.Advisor.advisor_name()
  @type market_quote :: Tai.Markets.Quote.t()
  @type config :: Config.t()
  @type order :: Tai.Orders.Order.t()

  @spec create(advisor_process, market_quote, config) :: {:ok, order}
  def create(advisor_process, market_quote, config, orders_provider \\ Tai.Orders) do
    price = EntryPrice.calculate(market_quote, config.product)

    %OrderSubmissions.BuyLimitGtc{
      venue_id: market_quote.venue_id,
      credential_id: config.fee.credential_id,
      venue_product_symbol: config.product.venue_symbol,
      product_symbol: config.product.symbol,
      price: price,
      qty: config.max_qty,
      product_type: config.product.type,
      post_only: true,
      order_updated_callback: {advisor_process, :entry_order}
    }
    |> orders_provider.create()
  end
end
