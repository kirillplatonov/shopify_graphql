module ShopifyGraphql
  class CreateBulkQuery
    include Mutation

    MUTATION = <<~GRAPHQL
      mutation($query: String!) {
        bulkOperationRunQuery(query: $query) {
          bulkOperation {
            id
            status
          }
          userErrors {
            field
            message
          }
        }
      }
    GRAPHQL

    def call(query:)
      response = execute(MUTATION, query: query)
      response.data = response.data.bulkOperationRunQuery
      handle_user_errors(response.data)
      response
    end
  end
end
