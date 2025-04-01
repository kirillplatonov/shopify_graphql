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
      assert error.error_codes.include?("TAKEN")
      assert_includes error.message, "Key is in use for Product metafields"
      assert_includes error.messages, "Key is in use for Product metafields on the 'xxx' namespace."
      assert error.fields.include?(["definition", "key"])
    end
  end

  test "server error" do
    fake("mutations/server_error.json", SIMPLE_QUERY)

    begin
      ShopifyGraphql.execute(SIMPLE_QUERY)
    rescue ShopifyGraphql::ServerError => error
      assert_equal 200, error.code
      assert_equal ["INTERNAL_SERVER_ERROR"], error.error_codes
      assert_includes error.messages, "Internal error. Looks like something went wrong on our end.\nRequest ID: XXXXX (include this in support requests)."
    end
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
end
