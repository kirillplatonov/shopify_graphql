require "test_helper"

class ErrorHandlingTest < ActiveSupport::TestCase
  SIMPLE_QUERY = <<~GRAPHQL
    query {
      shop {
        id
        name
        myshopifyDomain
      }
    }
  GRAPHQL

  METAFIELD_DEFINITION_CREATE = <<~GRAPHQL
    mutation($definition: MetafieldDefinitionInput!) {
      metafieldDefinitionCreate(definition: $definition) {
        createdDefinition {
          id
        }
        userErrors {
          field
          message
          code
        }
      }
    }
  GRAPHQL

  THROTTLED_BODY = {
    errors: [
      {
        message: "Throttled",
        extensions: {
          code: "THROTTLED",
          documentation: "https://shopify.dev/api/usage/rate-limits"
        }
      }
    ],
    extensions: {
      cost: {
        requestedQueryCost: 202,
        actualQueryCost: nil,
        throttleStatus: {
          maximumAvailable: 2000.0,
          currentlyAvailable: 22,
          restoreRate: 100.0
        }
      }
    }
  }

  ACCESS_DENIED_BODY = {
    data: {
      shop: {
        name: "Graphql Gem Test"
      },
      productsCount: nil
    },
    errors: [
      {
        message: "Access denied for productsCount field. Required access: `read_products` access scope.",
        path: ["productsCount"],
        extensions: {
          code: "ACCESS_DENIED",
          documentation: "https://shopify.dev/api/usage/access-scopes",
          requiredAccess: "`read_products` access scope."
        }
      }
    ],
    extensions: {
      cost: {
        requestedQueryCost: 2,
        actualQueryCost: 2,
        throttleStatus: {
          maximumAvailable: 2000.0,
          currentlyAvailable: 1998,
          restoreRate: 100.0
        }
      }
    }
  }

  class CreateMetafieldDefinition
    include ShopifyGraphql::Mutation

    def call(definition:)
      response = execute(METAFIELD_DEFINITION_CREATE, definition: definition)
      response.data = response.data.metafieldDefinitionCreate
      handle_user_errors(response.data)
      response
    end
  end

  test "handles invalid JSON response" do
    fake("error_page.html", SIMPLE_QUERY)

    assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end

  test "handles network error" do
    fake_error(Errno::ECONNRESET)

    assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end

  test "handles aborted connection" do
    fake_error(Errno::ECONNABORTED)

    error = assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_includes error.message, "Network error"
  end

  test "invalid input error" do
    fake("mutations/invalid_input_error.json", SIMPLE_QUERY)

    assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
  end

  test "user error" do
    fake("mutations/user_error.json", SIMPLE_QUERY)

    begin
      response = ShopifyGraphql.execute(SIMPLE_QUERY)
      ShopifyGraphql::Client.new.handle_user_errors(response.data.metafieldDefinitionCreate)
    rescue ShopifyGraphql::UserError => error
      assert_equal 200, error.code
      assert_equal "TAKEN", error.error_code
      assert error.error_codes.include?("TAKEN")
      assert_includes error.message, "Key is in use for Product metafields"
      assert_includes error.messages, "Key is in use for Product metafields on the 'xxx' namespace."
      assert error.fields.include?(["definition", "key"])
    end
  end

  test "multiple user errors" do
    fake("mutations/multiple_user_errors.json", SIMPLE_QUERY)

    begin
      response = ShopifyGraphql.execute(SIMPLE_QUERY)
      ShopifyGraphql::Client.new.handle_user_errors(response.data.metafieldsSet)
    rescue ShopifyGraphql::UserError => error
      assert_equal 200, error.code
      assert_equal "INVALID_VALUE", error.error_code
      assert error.error_codes.include?("INVALID_VALUE")
      assert_equal error.error_codes, ["INVALID_VALUE", "INVALID_VALUE"]
      assert_includes error.messages, "Value does not exist in provided choices: [\"Male\", \"Female\", \"Other\"]."
      assert_includes error.message, "2 fields have failed"
      assert_includes error.message, "Value has a maximum length of 10."
      assert_equal error.fields, [["metafields", "0", "value"], ["metafields", "1", "value"]]
    end
  end


  test "server error" do
    fake("mutations/server_error.json", SIMPLE_QUERY)

    begin
      ShopifyGraphql.execute(SIMPLE_QUERY)
    rescue ShopifyGraphql::ServerError => error
      assert_equal 200, error.code
      assert_equal "INTERNAL_SERVER_ERROR", error.error_code
      assert_equal ["INTERNAL_SERVER_ERROR"], error.error_codes
      assert_includes error.messages, "Internal error. Looks like something went wrong on our end.\nRequest ID: XXXXX (include this in support requests)."
    end
  end

  test "shop pending termination error" do
    fake("mutations/shop_pending_termination.json", SIMPLE_QUERY)

    error = assert_raises ShopifyGraphql::ShopPendingTermination do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal 200, error.code
    assert_equal "SHOP_PENDING_TERMINATION", error.error_code
    assert_equal ["SHOP_PENDING_TERMINATION"], error.error_codes
    assert_includes error.message, "Shop is under review"
  end

  test "bad request with hash errors" do
    stub_request(:post, API_PATH)
      .to_return(status: 400, body: { errors: { query: "Required parameter missing or invalid" } }.to_json)

    error = assert_raises ShopifyGraphql::BadRequest do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal 400, error.code
    assert_includes error.message, "Required parameter missing or invalid"
  end

  test "bad request with string errors" do
    stub_request(:post, API_PATH)
      .to_return(status: 400, body: { errors: "Bad request" }.to_json)

    error = assert_raises ShopifyGraphql::BadRequest do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal 400, error.code
    assert_includes error.message, "Bad request"
  end

  test "unprocessable entity" do
    stub_request(:post, API_PATH)
      .to_return(status: 422, body: { errors: ["Unprocessable entity"] }.to_json)

    error = assert_raises ShopifyGraphql::ResourceInvalid do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_kind_of ShopifyGraphql::ClientError, error
    assert_equal 422, error.code
    assert_includes error.message, "Unprocessable entity"
  end

  test "string errors" do
    stub_request(:post, API_PATH)
      .to_return(body: { errors: "Something went wrong" }.to_json)

    error = assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal 200, error.code
    assert_includes error.message, "Something went wrong"
    assert_equal ["Something went wrong"], error.messages
    assert_equal ["Something went wrong"], error.errors.map(&:message)
    assert_nil error.data
    assert_no_cost error
  end

  test "hash errors" do
    stub_request(:post, API_PATH)
      .to_return(body: { errors: { query: "Required parameter missing or invalid" } }.to_json)

    error = assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal 200, error.code
    assert_equal "Failed. Response message = query: Required parameter missing or invalid.", error.message
    assert_equal ["query: Required parameter missing or invalid"], error.messages
    assert_equal ["query: Required parameter missing or invalid"], error.errors.map(&:message)
  end

  test "throttled error exposes cost" do
    stub_request(:post, API_PATH).to_return(body: THROTTLED_BODY.to_json)

    error = assert_raises ShopifyGraphql::TooManyRequests do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal "THROTTLED", error.error_code
    assert_equal 22, error.points_left
    assert_equal 2000.0, error.points_limit
    assert_equal 100.0, error.points_restore_rate
    assert_equal 202, error.requested_query_cost
    assert_nil error.query_cost
    assert_instance_of ShopifyGraphql::Response, error.graphql_response
  end

  test "access denied error keeps partial data and errors" do
    stub_request(:post, API_PATH).to_return(body: ACCESS_DENIED_BODY.to_json)

    error = assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal ShopifyGraphql::ConnectionError, error.class
    assert_equal "ACCESS_DENIED", error.error_code
    assert_equal "Graphql Gem Test", error.data.shop.name
    assert_nil error.data.productsCount
    assert_equal 1, error.errors.size
    assert_equal ["productsCount"], error.errors.first.path
    assert_equal 2, error.query_cost
    assert_equal 1998, error.points_left
  end

  test "keeps all graphql errors" do
    body = ACCESS_DENIED_BODY.deep_dup
    body[:errors] << {
      message: "Access denied for orders field. Required access: `read_orders` access scope.",
      path: ["orders"],
      extensions: { code: "ACCESS_DENIED" }
    }
    stub_request(:post, API_PATH).to_return(body: body.to_json)

    error = assert_raises ShopifyGraphql::ConnectionError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_equal [["productsCount"], ["orders"]], error.errors.map(&:path)
    assert_equal ["ACCESS_DENIED"], error.error_codes
    assert_equal [ACCESS_DENIED_BODY[:errors].first[:message]], error.messages
  end

  test "mutation user error exposes cost" do
    fake("mutations/user_error.json", METAFIELD_DEFINITION_CREATE, definition: { key: "key" })

    error = assert_raises ShopifyGraphql::UserError do
      CreateMetafieldDefinition.call(definition: { key: "key" })
    end
    assert_equal "TAKEN", error.error_code
    assert_equal 10, error.query_cost
    assert_equal 10, error.requested_query_cost
    assert_equal 1990, error.points_left
    assert_equal 2000.0, error.points_limit
    assert_equal 100.0, error.points_restore_rate
    assert_nil error.data.createdDefinition
    assert_equal ["TAKEN"], error.errors.map(&:code)
  end

  test "user error exposes cost of passed response" do
    fake("mutations/user_error.json", METAFIELD_DEFINITION_CREATE)

    response = ShopifyGraphql.execute(METAFIELD_DEFINITION_CREATE)
    payload = response.data.metafieldDefinitionCreate
    error = assert_raises ShopifyGraphql::UserError do
      ShopifyGraphql.handle_user_errors(payload, response: response)
    end
    assert_same response, error.graphql_response
    assert_equal 10, error.query_cost
    assert_equal 1990, error.points_left
    assert_same payload, error.data
    assert_equal payload.userErrors, error.errors
  end

  test "module-level user error has no cost without response" do
    fake("mutations/user_error.json", METAFIELD_DEFINITION_CREATE)

    response = ShopifyGraphql.execute(METAFIELD_DEFINITION_CREATE)
    payload = response.data.metafieldDefinitionCreate
    error = assert_raises ShopifyGraphql::UserError do
      ShopifyGraphql.handle_user_errors(payload)
    end
    assert_nil error.graphql_response
    assert_no_cost error
    assert_same payload, error.data
  end

  test "handle_user_errors returns payload without user errors" do
    payload = OpenStruct.new(userErrors: [])

    assert_same payload, ShopifyGraphql::Client.new.handle_user_errors(payload)
  end

  test "graphql error without cost extensions" do
    fake("mutations/server_error.json", SIMPLE_QUERY)

    error = assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_nil error.data
    assert_equal ["INTERNAL_SERVER_ERROR"], error.errors.map { |e| e.extensions.code }
    assert_no_cost error
  end

  test "http error has no data, errors or cost" do
    stub_request(:post, API_PATH)
      .to_return(status: 400, body: { errors: "Bad request" }.to_json)

    error = assert_raises ShopifyGraphql::BadRequest do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_nil error.data
    assert_equal [], error.errors
    assert_nil error.graphql_response
    assert_no_cost error
  end

  test "network error has no data, errors or cost" do
    fake_error(Errno::ECONNRESET)

    error = assert_raises ShopifyGraphql::ServerError do
      ShopifyGraphql.execute(SIMPLE_QUERY)
    end
    assert_nil error.data
    assert_equal [], error.errors
    assert_nil error.graphql_response
    assert_no_cost error
  end

  test "error built without response has no data, errors or cost" do
    error = ShopifyGraphql::ResourceNotFound.new

    assert_nil error.data
    assert_equal [], error.errors
    assert_nil error.graphql_response
    assert_no_cost error
  end

  test "success response" do
    fake("queries/shop.json", SIMPLE_QUERY)

    response = ShopifyGraphql.execute(SIMPLE_QUERY)
    assert_equal "Graphql Gem Test", response.data.shop.name
    assert_equal 999, response.points_left
  end

  test "handle http response error" do
    fake("error_page.html", SIMPLE_QUERY)

    begin
      ShopifyGraphql.execute(SIMPLE_QUERY)
    rescue ShopifyAPI::Errors::HttpResponseError => error
      assert_equal 200, error.code
      assert_includes error.message, "Invalid JSON response"
    end
  end

  private

  def assert_no_cost(error)
    assert_nil error.query_cost
    assert_nil error.requested_query_cost
    assert_nil error.points_left
    assert_nil error.points_limit
    assert_nil error.points_restore_rate
  end
end
