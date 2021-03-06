defmodule Tai.Orders.CreateRejectedTest do
  use Tai.TestSupport.DataCase, async: false
  alias Tai.Orders.{Order, Submissions}

  @venue_order_id "df8e6bd0-a40a-42fb-8fea-b33ef4e34f14"
  @venue :venue_a
  @credential :main
  @credentials Map.put(%{}, @credential, %{})
  @submission_attrs %{venue_id: @venue, credential_id: @credential}

  setup do
    mock_venue(id: @venue, credentials: @credentials, adapter: Tai.VenueAdapters.Mock)

    :ok
  end

  [
    {:buy, Submissions.BuyLimitGtc},
    {:sell, Submissions.SellLimitGtc}
  ]
  |> Enum.each(fn {side, submission_type} ->
    @submission_type submission_type

    test "#{side} updates the relevant attributes" do
      submission = Support.Orders.build_submission_with_callback(@submission_type, @submission_attrs)
      Mocks.Responses.Orders.GoodTillCancel.rejected(@venue_order_id, submission)

      {:ok, _} = Tai.Orders.create(submission)

      assert_receive {
        :callback_fired,
        nil,
        %Order{status: :enqueued}
      }

      assert_receive {
        :callback_fired,
        %Order{status: :enqueued},
        %Order{status: :rejected} = rejected_order
      }

      assert rejected_order.venue_order_id == @venue_order_id
      assert %DateTime{} = rejected_order.last_venue_timestamp
    end
  end)
end
