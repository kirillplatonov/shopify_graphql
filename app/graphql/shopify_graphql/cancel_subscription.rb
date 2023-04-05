module ShopifyGraphql
  class CancelSubscription
    include Mutation

    MUTATION = <<~GRAPHQL
      mutation appSubscriptionCancel($id: ID!) {
        appSubscriptionCancel(id: $id) {
          appSubscription {
            id
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def call(id:)
      response = execute(MUTATION, id: id)
      response.data = response.data.appSubscriptionCancel
      handle_user_errors(response.data)
      response.data = parse_data(response.data)
      response
    end

    private

    def parse_data(data)
      subscription = Struct.new(id: data.appSubscription.id)
      Struct.new(subscription: subscription)
    end
  end
end
