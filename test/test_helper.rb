# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Disable warnings locally
$VERBOSE = ENV["CI"]

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "webmock/minitest"

class ActiveSupport::TestCase
  API_PATH = "https://test-shop.myshopify.com/admin/api/2024-07/graphql.json"

  setup do
    session = ShopifyAPI::Auth::Session.new(shop: "test-shop.myshopify.com", access_token: "test-token")
    ShopifyAPI::Context.activate_session(session)
  end

  teardown do
    ShopifyAPI::Context.deactivate_session
  end

  def fake(fixture_path, query, **variables)
    fixture = File.read File.expand_path("fixtures/#{fixture_path}", __dir__)
    body = { query: query, variables: variables }

    stub_request(:post, API_PATH)
      .with(body: body)
      .to_return(body: fixture)
  end

  def fake_error(error_class)
    stub_request(:post, API_PATH)
      .to_raise(error_class)
  end
end
