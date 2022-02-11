require "test_helper"

class CancelSubscriptionTest < ActiveSupport::TestCase
  test "cancels subscription" do
    subscription_id = "gid://shopify/AppSubscription/22229909587"
    fake(
      "mutations/cancel_subscription.json",
      ShopifyGraphql::CancelSubscription::MUTATION,
      id: subscription_id
    )

    response = ShopifyGraphql::CancelSubscription.call(id: subscription_id)
    subscription = response.data.subscription
    assert_equal subscription_id, subscription.id
  end
end
