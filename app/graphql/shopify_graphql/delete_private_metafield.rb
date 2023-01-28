module ShopifyGraphql
  class DeletePrivateMetafield
    include ShopifyGraphql::Mutation

    MUTATION = <<~GRAPHQL
      mutation privateMetafieldDelete($input: PrivateMetafieldDeleteInput!) {
        privateMetafieldDelete(input: $input) {
          deletedPrivateMetafieldId
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def call(namespace:, key:, owner: nil)
      input = {namespace: namespace, key: key}
      input[:owner] = owner if owner

      response = execute(MUTATION, input: input)
      handle_user_errors(response.data.privateMetafieldDelete)
      response.data = parse_data(response.data)
      response
    end

    private

    def parse_data(data)
      id = data.privateMetafieldDelete.deletedPrivateMetafieldId
      OpenStruct.new(
        deleted_private_metafield_id: id
      )
    end
  end
end
