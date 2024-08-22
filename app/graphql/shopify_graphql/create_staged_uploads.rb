module ShopifyGraphql
  class CreateStagedUploads
    include Mutation

    MUTATION = <<~GRAPHQL
      mutation stagedUploadsCreate($input: [StagedUploadInput!]!) {
        stagedUploadsCreate(input: $input) {
          stagedTargets {
            url
            resourceUrl
            parameters {
              name
              value
            }
          }
          userErrors{
            field,
            message
          }
        }
      }
    GRAPHQL

    def call(input:)
      response = execute(MUTATION, input: input)
      response.data = response.data.stagedUploadsCreate
      handle_user_errors(response.data)
      response
    end
  end
end
