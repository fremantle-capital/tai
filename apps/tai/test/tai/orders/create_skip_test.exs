defmodule Tai.Orders.CreateSkipTest do
  use ExUnit.Case, async: false
  import Support.Orders
  alias Tai.Orders.{Order, OrderSubmissions}

  setup do
    setup_orders(&start_supervised!/1)
    Tai.Settings.disable_send_orders!()

    :ok
  end

  [
    {:buy, OrderSubmissions.BuyLimitGtc},
    {:sell, OrderSubmissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the leaves qty" do
      submission = Support.OrderSubmissions.build_with_callback(@submission_type)

      {:ok, _} = Tai.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :skip} = skipped_order
      }

      assert skipped_order.leaves_qty == Decimal.new(0)
    end
  end)
end
