module ShopifyGraphql
  class CreateBulkMutation
    include Mutation

    MUTATION = <<~GRAPHQL
      mutation($mutation: String!, $stagedUploadPath: String!) {
        bulkOperationRunMutation(mutation: $mutation, stagedUploadPath: $stagedUploadPath) {
          bulkOperation {
            id
            status
          }
          userErrors {
            code
            field
            message
          }
        }
      }
    GRAPHQL

    def call(mutation:, staged_upload_path:)
      response = execute(MUTATION, mutation: mutation, stagedUploadPath: staged_upload_path)
      response.data = response.data.bulkOperationRunMutation
      handle_user_errors(response.data)
      response
    end
  end
end
