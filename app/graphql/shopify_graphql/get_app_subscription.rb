module ShopifyGraphql
  class GetAppSubscription
    include Query

    QUERY = <<~GRAPHQL
      #{AppSubscriptionFields::FRAGMENT}

      query($id: ID!) {
        node(id: $id) {
          ... AppSubscriptionFields
        }
      }
    GRAPHQL

    def call(id:)
      response = execute(QUERY, id: id)
      response.data = AppSubscriptionFields.parse(response.data.node)
      response
    end
  end
end
