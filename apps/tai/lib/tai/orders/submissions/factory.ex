defmodule Tai.Orders.OrderSubmissions.Factory do
  alias Tai.Orders.Order

  alias Tai.Orders.OrderSubmissions.{
    BuyLimitGtc,
    BuyLimitFok,
    BuyLimitIoc,
    SellLimitGtc,
    SellLimitFok,
    SellLimitIoc
  }

  @type order :: Order.t()
  @type submission ::
          BuyLimitGtc.t()
          | SellLimitGtc.t()
          | BuyLimitFok.t()
          | SellLimitFok.t()
          | BuyLimitIoc.t()
          | SellLimitIoc.t()

  @zero Decimal.new(0)

  @spec build!(submission) :: order | no_return
  def build!(submission) do
    qty = Decimal.abs(submission.qty)

    %Order{
      client_id: Ecto.UUID.generate(),
      venue_id: submission.venue_id,
      credential_id: submission.credential_id,
      venue_product_symbol: submission.venue_product_symbol,
      product_symbol: submission.product_symbol,
      product_type: submission.product_type,
      side: submission |> side,
      type: submission |> type,
      price: submission.price |> Decimal.abs(),
      qty: qty,
      leaves_qty: qty,
      cumulative_qty: @zero,
      time_in_force: submission |> time_in_force,
      post_only: submission |> post_only,
      status: :enqueued,
      close: submission.close,
      enqueued_at: Timex.now(),
      order_updated_callback: submission.order_updated_callback
    }
  end

  defp type(%BuyLimitGtc{}), do: :limit
  defp type(%BuyLimitFok{}), do: :limit
  defp type(%BuyLimitIoc{}), do: :limit
  defp type(%SellLimitGtc{}), do: :limit
  defp type(%SellLimitFok{}), do: :limit
  defp type(%SellLimitIoc{}), do: :limit

  defp side(%BuyLimitGtc{}), do: :buy
  defp side(%BuyLimitFok{}), do: :buy
  defp side(%BuyLimitIoc{}), do: :buy
  defp side(%SellLimitGtc{}), do: :sell
  defp side(%SellLimitFok{}), do: :sell
  defp side(%SellLimitIoc{}), do: :sell

  defp time_in_force(%BuyLimitGtc{}), do: :gtc
  defp time_in_force(%BuyLimitFok{}), do: :fok
  defp time_in_force(%BuyLimitIoc{}), do: :ioc
  defp time_in_force(%SellLimitGtc{}), do: :gtc
  defp time_in_force(%SellLimitFok{}), do: :fok
  defp time_in_force(%SellLimitIoc{}), do: :ioc

  defp post_only(%BuyLimitGtc{post_only: post_only}), do: post_only
  defp post_only(%BuyLimitFok{}), do: false
  defp post_only(%BuyLimitIoc{}), do: false
  defp post_only(%SellLimitGtc{post_only: post_only}), do: post_only
  defp post_only(%SellLimitFok{}), do: false
  defp post_only(%SellLimitIoc{}), do: false
end
