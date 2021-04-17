defmodule Tai.Orders.OrderSubmissions.SellLimitGtc do
  alias __MODULE__

  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type venue_product_symbol :: Tai.Venues.Product.venue_symbol()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type product_type :: Tai.Venues.Product.type()
  @type callback :: Tai.Orders.Order.callback()
  @type t :: %SellLimitGtc{
          venue_id: venue_id,
          credential_id: credential_id,
          venue_product_symbol: venue_product_symbol,
          product_symbol: product_symbol,
          product_type: product_type,
          price: Decimal.t(),
          qty: Decimal.t(),
          close: boolean | nil,
          post_only: boolean,
          order_updated_callback: callback
        }

  @enforce_keys ~w(
    venue_id
    credential_id
    venue_product_symbol
    product_symbol
    product_type
    price
    qty
    post_only
  )a
  defstruct ~w(
    venue_id
    credential_id
    venue_product_symbol
    product_symbol
    product_type
    price
    qty
    post_only
    close
    order_updated_callback
  )a
end
