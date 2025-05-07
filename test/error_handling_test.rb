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
