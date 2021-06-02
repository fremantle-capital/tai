defmodule Tai.VenueAdapters.Ftx.Stream.UpdateOrder do
  alias Tai.NewOrders.OrderTransitionWorker

  @date_format "{ISO:Extended}"

  def update(%{"clientId" => nil} = venue_order, received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: venue_order,
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
    })
  end

  def update(
        %{
          "status" => "new",
          "clientId" => client_id,
          "id" => id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "remainingSize" => remaining_size
        },
        received_at,
        _state
      ) do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(received_at)
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()
    leaves_qty = remaining_size |> Tai.Utils.Decimal.cast!()
    venue_order_id = id |> Integer.to_string()

    OrderTransitionWorker.apply(client_id, %{
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      leaves_qty: leaves_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: venue_timestamp,
      __type__: :open
    })
  end

  def update(
        %{
          "status" => "closed",
          "clientId" => client_id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "size" => size
        },
        received_at,
        _state
      )
      when filled_size != size do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(received_at)
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)

    OrderTransitionWorker.apply(client_id, %{
      last_received_at: last_received_at,
      last_venue_timestamp: venue_timestamp,
      __type__: :cancel
    })
  end

  def update(
        %{
          "status" => "open",
          "clientId" => client_id,
          "id" => id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "remainingSize" => remaining_size
        },
        received_at,
        _state
      ) do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(received_at)
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()
    leaves_qty = remaining_size |> Tai.Utils.Decimal.cast!()
    venue_order_id = id |> Integer.to_string()

    OrderTransitionWorker.apply(client_id, %{
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      leaves_qty: leaves_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: venue_timestamp,
      __type__: :partial_fill
    })
  end

  def update(
        %{
          "status" => "closed",
          "clientId" => client_id,
          "id" => id,
          "createdAt" => created_at,
          "filledSize" => filled_size,
          "size" => size
        },
        received_at,
        _state
      )
      when filled_size == size do
    {:ok, last_received_at} = Tai.Time.monotonic_to_date_time(received_at)
    {:ok, venue_timestamp} = Timex.parse(created_at, @date_format)
    cumulative_qty = filled_size |> Tai.Utils.Decimal.cast!()
    venue_order_id = id |> Integer.to_string()

    OrderTransitionWorker.apply(client_id, %{
      venue_order_id: venue_order_id,
      cumulative_qty: cumulative_qty,
      last_received_at: last_received_at,
      last_venue_timestamp: venue_timestamp,
      __type__: :fill
    })
  end

  def update(venue_order, received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: venue_order,
      received_at: received_at |> Tai.Time.monotonic_to_date_time!()
    })
  end
end
