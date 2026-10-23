require "test_helper"

class CreateBulkQueryTest < ActiveSupport::TestCase
  BULK_QUERY = <<~GRAPHQL
    {
      products {
        edges {
          node {
            id
          }
        }
      }
    }
  GRAPHQL

  test "creates bulk query without groupObjects by default" do
    fake(
      "mutations/create_bulk_query.json",
      ShopifyGraphql::CreateBulkQuery::MUTATION,
      query: BULK_QUERY
    )

    response = ShopifyGraphql::CreateBulkQuery.call(query: BULK_QUERY)

    assert_equal "gid://shopify/BulkOperation/720918", response.data.bulkOperation.id
    assert_equal "CREATED", response.data.bulkOperation.status
    assert_requested(:post, API_PATH) do |request|
      body = JSON.parse(request.body)
      body["query"] == ShopifyGraphql::CreateBulkQuery::MUTATION &&
        !body["query"].include?("groupObjects") &&
        body["variables"] == { "query" => BULK_QUERY }
    end
  end

  [true, false].each do |group_objects|
    test "creates bulk query with groupObjects: #{group_objects}" do
      fake(
        "mutations/create_bulk_query.json",
        ShopifyGraphql::CreateBulkQuery::MUTATION_WITH_GROUP_OBJECTS,
        query: BULK_QUERY,
        groupObjects: group_objects
      )

      response = ShopifyGraphql::CreateBulkQuery.call(query: BULK_QUERY, group_objects: group_objects)

      assert_equal "gid://shopify/BulkOperation/720918", response.data.bulkOperation.id
      assert_requested(:post, API_PATH) do |request|
        body = JSON.parse(request.body)
        body["query"] == ShopifyGraphql::CreateBulkQuery::MUTATION_WITH_GROUP_OBJECTS &&
          body["variables"] == { "query" => BULK_QUERY, "groupObjects" => group_objects }
      end
    end
  end
end
