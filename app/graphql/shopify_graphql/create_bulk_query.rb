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
            code
            field
            message
          }
        }
      }
    GRAPHQL

    # groupObjects is available since API version 2025-07
    MUTATION_WITH_GROUP_OBJECTS = <<~GRAPHQL
      mutation($query: String!, $groupObjects: Boolean!) {
        bulkOperationRunQuery(query: $query, groupObjects: $groupObjects) {
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

    def call(query:, group_objects: nil)
      response = if group_objects.nil?
        execute(MUTATION, query: query)
      else
        execute(MUTATION_WITH_GROUP_OBJECTS, query: query, groupObjects: group_objects)
      end
      response.data = response.data.bulkOperationRunQuery
      handle_user_errors(response.data)
      response
    end
  end
end
