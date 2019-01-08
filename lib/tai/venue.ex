defmodule Tai.Venue do
  @type config :: Tai.Config.t()
  @type adapter :: Tai.Venues.Adapter.t()
  @type product :: Tai.Venues.Product.t()
  @type asset_balance :: Tai.Venues.AssetBalance.t()
  @type order :: Tai.Trading.Order.t()
  @type order_response :: Tai.Trading.OrderResponse.t()
  @type venue_order_id :: String.t()
  @type amend_attrs :: Tai.Trading.Orders.Amend.attrs()
  @type shared_error_reason :: :timeout | Tai.CredentialError.t()
  @type create_order_error_reason ::
          :not_implemented
          | shared_error_reason
          | Tai.Trading.InsufficientBalanceError.t()
  @type amend_order_error_reason ::
          :not_implemented
          | shared_error_reason
  @type cancel_order_error_reason ::
          :not_implemented
          | :not_found
          | shared_error_reason

  @spec products(adapter :: adapter) :: {:ok, [product]}
  def products(%Tai.Venues.Adapter{adapter: adapter, id: exchange_id}) do
    adapter.products(exchange_id)
  end

  @spec asset_balances(adapter :: adapter, account_id :: atom) :: {:ok, [asset_balance]}
  def asset_balances(
        %Tai.Venues.Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.asset_balances(exchange_id, account_id, credentials)
  end

  @spec maker_taker_fees(adapter :: adapter, account_id :: atom) ::
          {:ok, {maker :: Decimal.t(), taker :: Decimal.t()}}
  def maker_taker_fees(
        %Tai.Venues.Adapter{adapter: adapter, id: exchange_id, accounts: accounts},
        account_id
      ) do
    {:ok, credentials} = Map.fetch(accounts, account_id)
    adapter.maker_taker_fees(exchange_id, account_id, credentials)
  end

  @spec create_order(order) :: {:ok, order_response} | {:error, create_order_error_reason}
  def create_order(%Tai.Trading.Order{} = order, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.create_order(order, credentials)
  end

  @spec amend_order(order, amend_attrs) ::
          {:ok, order_response} | {:error, amend_order_error_reason}
  def amend_order(
        %Tai.Trading.Order{} = order,
        attrs,
        adapters \\ Tai.Venues.Config.parse_adapters()
      ) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.amend_order(order.venue_order_id, attrs, credentials)
  end

  @spec cancel_order(order) :: {:ok, venue_order_id} | {:error, cancel_order_error_reason}
  def cancel_order(%Tai.Trading.Order{} = order, adapters \\ Tai.Venues.Config.parse_adapters()) do
    {venue_adapter, credentials} = find_venue_adapter_and_credentials(order, adapters)
    venue_adapter.adapter.cancel_order(order.venue_order_id, credentials)
  end

  defp find_venue_adapter_and_credentials(order, adapters) do
    venue_adapter = adapters |> Map.fetch!(order.exchange_id)
    credentials = Map.fetch!(venue_adapter.accounts, order.account_id)

    {venue_adapter, credentials}
  end
end
