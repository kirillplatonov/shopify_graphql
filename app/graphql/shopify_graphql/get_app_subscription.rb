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
      response.data = parse_data(response.data)
      response
    end

    private

    def parse_data(data)
      unless data.node
        raise ResourceNotFound.new, "Subscription not found"
      end

      OpenStruct.new(
        subscription: AppSubscriptionFields.parse(data.node),
      )
    end
  end
end
