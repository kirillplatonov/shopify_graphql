# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
- `rake test` - Run all tests
- `bundle exec rake test` - Run all tests with bundler
- `ruby -Itest test/specific_test.rb` - Run a single test file

### Development
- `bundle install` - Install gem dependencies
- `rake` - Default task (runs tests)
- `bundle exec rake` - Run with bundler

### Building
- `gem build shopify_graphql.gemspec` - Build the gem
- `gem install shopify_graphql-*.gem` - Install built gem locally

## Architecture

This is a Ruby gem that provides a wrapper around the Shopify GraphQL Admin API. The gem follows these architectural patterns:

### Core Components

1. **Client Layer** (`lib/shopify_graphql/client.rb`):
   - Wraps `ShopifyAPI::Clients::Graphql::Admin`
   - Handles HTTP errors and GraphQL errors
   - Provides unified error handling and response parsing
   - Converts responses to OpenStruct objects for easy access

2. **Query/Mutation Mixins** (`lib/shopify_graphql/query.rb`, `lib/shopify_graphql/mutation.rb`):
   - Provide `include ShopifyGraphql::Query` or `include ShopifyGraphql::Mutation`
   - Add class methods for easy instantiation: `ClassName.call(...)`
   - Delegate `execute` and `handle_user_errors` methods to client

3. **Response Wrapper** (`lib/shopify_graphql/response.rb`):
   - Wraps GraphQL responses with rate limit information
   - Provides methods: `points_left`, `points_limit`, `points_restore_rate`, `query_cost`, `points_maxed?`

4. **Exception Hierarchy** (`lib/shopify_graphql/exceptions.rb`):
   - Custom exceptions for different HTTP error codes
   - Special `UserError` exception for GraphQL userErrors
   - All inherit from `ShopifyAPI::Errors::HttpResponseError`

### Built-in GraphQL Wrappers (`app/graphql/shopify_graphql/`)

Pre-built GraphQL operations following the gem's conventions:
- `CurrentShop` - Get shop information (equivalent to `ShopifyAPI::Shop.current`)
- Subscription management: `CreateRecurringSubscription`, `CreateUsageSubscription`, `CancelSubscription`, `GetAppSubscription`
- Metafield operations: `UpsertPrivateMetafield`, `DeletePrivateMetafield`
- Bulk operations: `CreateBulkQuery`, `CreateBulkMutation`, `GetBulkOperation`
- File uploads: `CreateStagedUploads`

### Naming Conventions

The gem enforces these conventions for organizing GraphQL code:
- Use `app/graphql/` folder for GraphQL-related code
- Queries: Use `Get` prefix (e.g., `GetProduct`, `GetAppSubscription`)
- Mutations: Use imperative names (e.g., `CreateUsageSubscription`, `UpdateProduct`)
- Fields: Use `Fields` suffix (e.g., `ProductFields`, `AppSubscriptionFields`)
- Organize related operations in the same namespace

### Error Handling

The gem provides comprehensive error handling:
- HTTP errors are mapped to specific exception classes
- GraphQL errors are handled by `Client#handle_graphql_errors`
- User errors from mutations should be handled with `handle_user_errors(response.data)`
- Network errors (timeouts, connection issues) are caught and re-raised as `ServerError`

### Session Management

Depends on `shopify_app` gem for authentication. All GraphQL operations must be wrapped in:
```ruby
shop.with_shopify_session do
  # GraphQL operations here
end
```

### Testing

- Uses Minitest framework
- Test helper sets up fake Shopify session and WebMock for API stubbing
- Fixtures stored in `test/fixtures/` directory
- Helper method `fake(fixture_path, query, **variables)` for stubbing GraphQL requests

## Development Notes

- Ruby 3.0+ required
- Depends on `shopify_api` >= 13.4 and `shopify_app` >= 19.0
- Engine integration available for Rails applications
- Webhook functionality is deprecated and will be removed in v3.0