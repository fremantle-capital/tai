defmodule Tai.Venues.Adapter do
  alias Tai.Orders

  @type t :: module
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type credentials :: Tai.Venue.credentials()
  @type product :: Tai.Venues.Product.t()
  @type funding_rate :: Tai.Venues.FundingRate.t()
  @type account :: Tai.Venues.Account.t()
  @type position :: Tai.Trading.Position.t()
  @type order :: Tai.Orders.Order.t()
  @type create_response :: Orders.Responses.Create.t() | Orders.Responses.CreateAccepted.t()
  @type amend_response :: Orders.Responses.Amend.t()
  @type amend_bulk_response :: [amend_response]
  @type cancel_response :: Orders.Responses.Cancel.t() | Orders.Responses.CancelAccepted.t()
  @type amend_attrs :: Tai.Orders.Worker.amend_attrs()
  @type shared_error_reason ::
          :not_implemented
          | :timeout
          | :connect_timeout
          | :overloaded
          | :rate_limited
          | {:credentials, reason :: term}
          | {:nonce_not_increasing, String.t()}
          | {:unhandled, reason :: term}
  @type positions_error_reason :: shared_error_reason | :not_supported
  @type create_order_error_reason ::
          shared_error_reason | :insufficient_balance | :insufficient_position
  @type amend_order_error_reason ::
          shared_error_reason
          | :insufficient_balance
          | :insufficient_position
          | :not_found
          | :not_supported
  @type cancel_order_error_reason :: shared_error_reason | :not_found

  @callback stream_supervisor :: module
  @callback products(venue_id) :: {:ok, [product]} | {:error, shared_error_reason}
  @callback funding_rates(venue_id) :: {:ok, [funding_rate]} | {:error, shared_error_reason}
  @callback accounts(venue_id, credential_id, credentials) ::
              {:ok, [account]} | {:error, shared_error_reason}
  @callback positions(venue_id, credential_id, credentials) ::
              {:ok, [position]} | {:error, positions_error_reason}
  @callback maker_taker_fees(venue_id, credential_id, credentials) ::
              {:ok, {maker :: Decimal.t(), taker :: Decimal.t()} | nil}
              | {:error, shared_error_reason}
  @callback create_order(order, credentials) ::
              {:ok, create_response} | {:error, create_order_error_reason}
  @callback amend_order(order, amend_attrs, credentials) ::
              {:ok, amend_response} | {:error, amend_order_error_reason}
  @callback amend_bulk_orders([{order, amend_attrs}], credentials) ::
              {:ok, amend_bulk_response} | {:error, amend_order_error_reason}
  @callback cancel_order(order, credentials) ::
              {:ok, cancel_response} | {:error, cancel_order_error_reason}
end
