defmodule Tai.VenueAdapters.Bitmex.Stream.UpdateOrder do
  alias Tai.VenueAdapters.Bitmex.ClientId
  alias Tai.NewOrders.OrderTransitionWorker

  def apply(%{"clOrdID" => cl_ord_id, "ordStatus" => order_status} = msg, received_at, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()

    with {:ok, client_id} <- extract_client_id(cl_ord_id),
         {:ok, type} <- transition_type(order_status) do
      merged_attrs = msg
                     |> transition_attrs()
                     |> Map.put(:last_received_at, last_received_at)
                     # |> Map.put(:last_venue_timestamp, venue_timestamp)
                     |> Map.put(:__type__, type)

      OrderTransitionWorker.apply(client_id, merged_attrs)
    else
      # TODO: Need to write unit test for :invalid_client_id
      # {:error, :invalid_state} ->
      {:error, reason} when reason in [:invalid_state, :invalid_client_id] ->
        warn_unhandled(msg, last_received_at, state)
    end
  end

  def apply(msg, received_at, state) do
    {:ok, last_received_at} = received_at |> Tai.Time.monotonic_to_date_time()
    warn_unhandled(msg, last_received_at, state)
  end

  defp warn_unhandled(msg, last_received_at, state) do
    TaiEvents.warn(%Tai.Events.StreamMessageUnhandled{
      venue_id: state.venue,
      msg: msg,
      received_at: last_received_at
    })
  end

  defp extract_client_id(cl_ord_id) do
    case cl_ord_id do
      "gtc-" <> encoded_client_id -> 
        decoded_client_id = ClientId.from_base64(encoded_client_id)
        {:ok, decoded_client_id}

      _ -> 
        {:error, :invalid_client_id}
    end
  end

  @canceled "Canceled"
  # @filled "Filled"
  @partially_filled "PartiallyFilled"

  defp transition_type(s) when s == @canceled, do: {:ok, :cancel}
  # defp transition_type(s) when s == @pending, do: {:ok, :open}
  defp transition_type(s) when s == @partially_filled, do: {:ok, :partial_fill}
  # defp transition_type(s) when s == @fully_filled, do: {:ok, :fill}
  defp transition_type(_), do: {:error, :invalid_state}

  defp transition_attrs(%{"ordStatus" => order_status} = _msg) do
    case order_status do
      s when s == @canceled ->
        %{}

      # s when s == @pending or s == @partially_filled ->
      #   venue_order_id = Map.fetch!(msg, "order_id")
      #   size = Map.fetch!(msg, "size")
      #   cumulative_qty = msg |> filled() |> Decimal.new()
      #   leaves_qty = size |> Decimal.new() |> Decimal.sub(cumulative_qty)

      #   %{
      #     venue_order_id: venue_order_id,
      #     cumulative_qty: cumulative_qty,
      #     leaves_qty: leaves_qty,
      #   }

      # s when s == @fully_filled ->
      #   venue_order_id = Map.fetch!(msg, "order_id")
      #   cumulative_qty = msg |> filled() |> Decimal.new()

      #   %{
      #     venue_order_id: venue_order_id,
      #     cumulative_qty: cumulative_qty
      #   }
    end
  end
end
