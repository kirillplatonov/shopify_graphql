# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Disable warnings locally
$VERBOSE = ENV["CI"]

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "webmock/minitest"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end

class ActiveSupport::TestCase
  setup do
    session = ShopifyAPI::Auth::Session.new(shop: "test-shop.myshopify.com", access_token: "test-token")
    ShopifyAPI::Context.activate_session(session)
  end

  teardown do
    ShopifyAPI::Context.deactivate_session
  end

  def fake(fixture_path, query, **variables)
    api_path = "https://test-shop.myshopify.com/admin/api/2023-07/graphql.json"
    fixture = File.read File.expand_path("fixtures/#{fixture_path}", __dir__)
    body = { query: query, variables: variables }

    stub_request(:post, api_path)
      .with(body: body)
      .to_return(body: fixture)
  end
end
