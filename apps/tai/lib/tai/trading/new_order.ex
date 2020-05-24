defmodule Tai.Trading.NewOrder do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  @type client_id :: Ecto.UUID.t()
  @type venue_order_id :: String.t()
  @type venue_id :: Tai.Venue.id()
  @type credential_id :: Tai.Venue.credential_id()
  @type product_symbol :: Tai.Venues.Product.symbol()
  @type product_type :: Tai.Venues.Product.type()
  @type side :: :buy | :sell
  @type time_in_force :: :gtc | :fok | :ioc
  @type type :: :limit
  @type status ::
          :enqueued
          | :skip
          | :create_accepted
          | :open
          | :partially_filled
          | :filled
          | :expired
          | :rejected
          | :create_error
          | :pending_amend
          | :amend_error
          | :pending_cancel
          | :cancel_accepted
          | :canceled
          | :cancel_error
  @type callback :: fun | atom | pid | {atom | pid, term} | nil
  @type t :: %NewOrder{
          client_id: client_id,
          venue_order_id: venue_order_id | nil,
          venue_id: venue_id,
          credential_id: credential_id,
          side: side,
          status: status,
          product_symbol: product_symbol,
          product_type: product_type,
          time_in_force: time_in_force,
          type: type,
          price: Decimal.t(),
          qty: Decimal.t(),
          leaves_qty: Decimal.t(),
          cumulative_qty: Decimal.t(),
          post_only: boolean,
          close: boolean | nil,
          enqueued_at: DateTime.t(),
          last_received_at: DateTime.t() | nil,
          last_venue_timestamp: DateTime.t() | nil,
          updated_at: DateTime.t() | nil,
          order_updated_callback: callback
        }

  # @primary_key {:client_id, :string, []}
  @primary_key {:client_id, :binary_id, [autogenerate: false]}
  @foreign_key_type :binary_id
  schema "orders" do
    field(:venue_id, :string)
    field(:venue_order_id, :string)
    field(:product_symbol, :string)
    field(:product_type, :string)
    field(:credential_id, :string)
    field(:side, :string)
    field(:price, :decimal)
    field(:qty, :decimal)
    field(:leaves_qty, :decimal)
    field(:cumulative_qty, :decimal)
    field(:status, :string)
    field(:time_in_force, :string)
    field(:type, :string)
    field(:post_only, :boolean)
    field(:close, :boolean)
    field(:enqueued_at, :utc_datetime)
    field(:last_received_at, :utc_datetime)
    field(:last_venue_timestamp, :utc_datetime)
    field(:updated_at, :utc_datetime)
    field(:error_reason, :string)
    # order_updated_callback
    # field(:updated_at, :utc_datetime)

    timestamps()
  end

  @doc false
  def changeset(balance, attrs) do
    balance
    |> cast(attrs, [
      # :start_time,
      # :finish_time,
      # :usd,
      # :btc_usd_venue,
      # :btc_usd_symbol,
      # :btc_usd_price,
      # :usd_quote_venue,
      # :usd_quote_asset
    ])
    |> validate_required([
      :venue_id,
      :venue_order_id,
      :product_symbol,
      :product_type,
      :credential_id,
      :side,
      :price,
      :qty,
      :leaves_qty,
      :cumulative_qty,
      :status,
      :time_in_force,
      :type,
      :post_only,
      :close,
      :enqueued_at,
      :last_received_at,
      :last_venue_timestamp,
      :updated_at,
      :error_reason
    ])
  end
end
