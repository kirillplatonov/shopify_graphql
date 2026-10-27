# Shopify Graphql

Less painful way to work with [Shopify Graphql API](https://shopify.dev/api/admin-graphql) in Ruby. This library is a tiny wrapper on top of [`shopify_api`](https://github.com/Shopify/shopify-api-ruby) gem. It provides a simple API for Graphql calls, better error handling, and Graphql webhooks integration (deprecated).

## Features

- Simple API for Graphql queries and mutations
- Conventions for organizing Graphql code
- ActiveResource-like error handling
- Graphql and user error handlers
- Auto-conversion of responses to OpenStruct
- Graphql webhooks integration for Rails (deprecated, see [Graphql webhooks](#graphql-webhooks-deprecated))
- Wrappers for Graphql rate limit extensions
- Built-in calls for common Graphql calls

## Dependencies

- [`shopify_api`](https://github.com/Shopify/shopify-api-ruby) v13.4+
- [`shopify_app`](https://github.com/Shopify/shopify_app) v19+

> For `shopify_api` < v10 use [`0-4-stable`](https://github.com/kirillplatonov/shopify_graphql/tree/0-4-stable) branch.

## Installation

Add `shopify_graphql` to your Gemfile:

```bash
bundle add shopify_graphql
```

This gem relies on `shopify_app` for authentication so no extra setup is required. But you still need to wrap your Graphql calls with `shop.with_shopify_session`:

```rb
shop.with_shopify_session do
  # your calls to graphql
end
```

## Conventions

To better organize your Graphql code use the following conventions:

- Create wrappers for all of your queries and mutations to isolate them
- Put all Graphql-related code into `app/graphql` folder
- Use `Fields` suffix to name fields (eg `AppSubscriptionFields`)
- Use `Get` prefix to name queries (eg `GetProducts` or `GetAppSubscription`)
- Use imperative to name mutations (eg `CreateUsageSubscription` or `BulkUpdateVariants`)

## Usage examples

### Simple query

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/get_product.rb

class GetProduct
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query($id: ID!) {
      product(id: $id) {
        handle
        title
        description
      }
    }
  GRAPHQL

  def call(id:)
    response = execute(QUERY, id: id)
    response.data = response.data.product
    response
  end
end
```

Usage:

```rb
product = GetProduct.call(id: "gid://shopify/Product/12345").data
puts product.handle
puts product.title
```
</details>

### Query with custom headers

<details><summary>Click to expand</summary>
You can pass custom headers to any GraphQL query or mutation by using the `headers` parameter. A common use case is setting the `Accept-Language` header to retrieve content in specific languages:

```rb
# Pass custom headers to a direct GraphQL call to get French content
response = ShopifyGraphql.execute(QUERY, headers: { "Accept-Language" => "fr" })

# Or create a language-aware query wrapper
class GetProduct
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query($id: ID!) {
      product(id: $id) {
        id
        title
        description
        seo {
          title
          description
        }
      }
    }
  GRAPHQL

  def call(id:, language: nil)
    headers = language ? { "Accept-Language" => language } : nil
    response = execute(QUERY, headers: headers, id: id)
    response.data = response.data.product
    response
  end
end

# Then use it to get content in different languages
french_product = GetProduct.call(
  id: "gid://shopify/Product/12345",
  language: "fr"
).data

puts french_product.title       # => "Le Produit"
puts french_product.description # => "Description en français"

# Get content in Japanese
japanese_product = GetProduct.call(
  id: "gid://shopify/Product/12345",
  language: "ja"
).data

puts japanese_product.title     # => "商品名"
puts japanese_product.description # => "商品の説明"
```

The `Accept-Language` header tells Shopify which language to return the content in. This is particularly useful for:
- Retrieving translated content for products, collections, and pages
- Building multi-language storefronts
- Showing localized SEO content

You can also use custom headers for other purposes like passing metadata or context with your GraphQL requests.
</details>

### Query with data parsing

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/get_product.rb

class GetProduct
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query($id: ID!) {
      product(id: $id) {
        id
        title
        featuredImage {
          source: url
        }
      }
    }
  GRAPHQL

  def call(id:)
    response = execute(QUERY, id: id)
    response.data = parse_data(response.data.product)
    response
  end

  private

  def parse_data(data)
    OpenStruct.new(
      id: data.id,
      title: data.title,
      featured_image: data.featuredImage&.source
    )
  end
end
```

Usage:

```rb
product = GetProduct.call(id: "gid://shopify/Product/12345").data
puts product.id
puts product.title
puts product.featured_image
```
</details>

### Query with fields

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/product_fields.rb

class ProductFields
  FRAGMENT = <<~GRAPHQL
    fragment ProductFields on Product {
      id
      title
      featuredImage {
        source: url
      }
    }
  GRAPHQL

  def self.parse(data)
    OpenStruct.new(
      id: data.id,
      title: data.title,
      featured_image: data.featuredImage&.source
    )
  end
end
```

```rb
# app/graphql/get_product.rb

class GetProduct
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    #{ProductFields::FRAGMENT}

    query($id: ID!) {
      product(id: $id) {
        ... ProductFields
      }
    }
  GRAPHQL

  def call(id:)
    response = execute(QUERY, id: id)
    response.data = ProductFields.parse(response.data.product)
    response
  end
end
```

Usage:

```rb
product = GetProduct.call(id: "gid://shopify/Product/12345").data
puts product.id
puts product.title
puts product.featured_image
```
</details>

### Simple collection query

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/get_products.rb

class GetProducts
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    query {
      products(first: 5) {
        edges {
          node {
            id
            title
            featuredImage {
              source: url
            }
          }
        }
      }
    }
  GRAPHQL

  def call
    response = execute(QUERY)
    response.data = parse_data(response.data.products.edges)
    response
  end

  private

  def parse_data(data)
    return [] if data.blank?

    data.compact.map do |edge|
      OpenStruct.new(
        id: edge.node.id,
        title: edge.node.title,
        featured_image: edge.node.featuredImage&.source
      )
    end
  end
end
```

Usage:

```rb
products = GetProducts.call.data
products.each do |product|
  puts product.id
  puts product.title
  puts product.featured_image
end
```
</details>

### Collection query with fields

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/product_fields.rb

class ProductFields
  FRAGMENT = <<~GRAPHQL
    fragment ProductFields on Product {
      id
      title
      featuredImage {
        source: url
      }
    }
  GRAPHQL

  def self.parse(data)
    OpenStruct.new(
      id: data.id,
      title: data.title,
      featured_image: data.featuredImage&.source
    )
  end
end
```

```rb
# app/graphql/get_products.rb

class GetProducts
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    #{ProductFields::FRAGMENT}

    query {
      products(first: 5) {
        edges {
          cursor
          node {
            ... ProductFields
          }
        }
      }
    }
  GRAPHQL

  def call
    response = execute(QUERY)
    response.data = parse_data(response.data.products.edges)
    response
  end

  private

  def parse_data(data)
    return [] if data.blank?

    data.compact.map do |edge|
      OpenStruct.new(
        cursor: edge.cursor,
        node: ProductFields.parse(edge.node)
      )
    end
  end
end
```

Usage:

```rb
products = GetProducts.call.data
products.each do |edge|
  puts edge.cursor
  puts edge.node.id
  puts edge.node.title
  puts edge.node.featured_image
end
```
</details>

### Collection query with pagination

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/product_fields.rb

class ProductFields
  FRAGMENT = <<~GRAPHQL
    fragment ProductFields on Product {
      id
      title
      featuredImage {
        source: url
      }
    }
  GRAPHQL

  def self.parse(data)
    OpenStruct.new(
      id: data.id,
      title: data.title,
      featured_image: data.featuredImage&.source
    )
  end
end
```

```rb
# app/graphql/get_products.rb

class GetProducts
  include ShopifyGraphql::Query

  LIMIT = 5
  QUERY = <<~GRAPHQL
    #{ProductFields::FRAGMENT}

    query($cursor: String) {
      products(first: #{LIMIT}, after: $cursor) {
        edges {
          node {
            ... ProductFields
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  GRAPHQL

  def call
    response = execute(QUERY)
    data = parse_data(response.data.products.edges)

    while response.data.products.pageInfo.hasNextPage
      response = execute(QUERY, cursor: response.data.products.pageInfo.endCursor)
      data += parse_data(response.data.products.edges)
    end

    response.data = data
    response
  end

  private

  def parse_data(data)
    return [] if data.blank?

    data.compact.map do |edge|
      ProductFields.parse(edge.node)
    end
  end
end
```

Usage:

```rb
products = GetProducts.call.data
products.each do |product|
  puts product.id
  puts product.title
  puts product.featured_image
end
```
</details>

### Collection query with block

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/product_fields.rb

class ProductFields
  FRAGMENT = <<~GRAPHQL
    fragment ProductFields on Product {
      id
      title
      featuredImage {
        source: url
      }
    }
  GRAPHQL

  def self.parse(data)
    OpenStruct.new(
      id: data.id,
      title: data.title,
      featured_image: data.featuredImage&.source
    )
  end
end
```

```rb
# app/graphql/get_products.rb

class GetProducts
  include ShopifyGraphql::Query

  LIMIT = 5
  QUERY = <<~GRAPHQL
    #{ProductFields::FRAGMENT}

    query($cursor: String) {
      products(first: #{LIMIT}, after: $cursor) {
        edges {
          node {
            ... ProductFields
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  GRAPHQL

  def call(&block)
    response = execute(QUERY)
    response.data.products.edges.each do |edge|
      block.call ProductFields.parse(edge.node)
    end

    while response.data.products.pageInfo.hasNextPage
      response = execute(QUERY, cursor: response.data.products.pageInfo.endCursor)
      response.data.products.edges.each do |edge|
        block.call ProductFields.parse(edge.node)
      end
    end

    response
  end
end
```

Usage:

```rb
GetProducts.call do |product|
  puts product.id
  puts product.title
  puts product.featured_image
end
```
</details>

### Collection query with nested pagination

<details><summary>Click to expand</summary>
Definition:

```rb
# app/graphql/get_collections_with_products.rb

class GetCollectionsWithProducts
  include ShopifyGraphql::Query

  COLLECTIONS_LIMIT = 1
  PRODUCTS_LIMIT = 25
  QUERY = <<~GRAPHQL
    query ($cursor: String) {
      collections(first: #{COLLECTIONS_LIMIT}, after: $cursor) {
        edges {
          node {
            id
            title
            products(first: #{PRODUCTS_LIMIT}) {
              edges {
                node {
                  id
                }
              }
            }
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  GRAPHQL

  def call
    response = execute(QUERY)
    data = parse_data(response.data.collections.edges)

    while response.data.collections.pageInfo.hasNextPage
      response = execute(QUERY, cursor: response.data.collections.pageInfo.endCursor)
      data += parse_data(response.data.collections.edges)
    end

    response.data = data
    response
  end

  private

  def parse_data(data)
    return [] if data.blank?

    data.compact.map do |edge|
      OpenStruct.new(
        id: edge.node.id,
        title: edge.node.title,
        products: edge.node.products.edges.map do |product_edge|
          OpenStruct.new(id: product_edge.node.id)
        end
      )
    end
  end
end
```

Usage:

```rb
collections = GetCollectionsWithProducts.call.data
collections.each do |collection|
  puts collection.id
  puts collection.title
  collection.products.each do |product|
    puts product.id
  end
end
```
</details>

### Mutation

<details><summary>Click to expand</summary>

Definition:

```rb
# app/graphql/update_product.rb

class UpdateProduct
  include ShopifyGraphql::Mutation

  MUTATION = <<~GRAPHQL
    mutation($input: ProductInput!) {
      productUpdate(input: $input) {
        product {
          id
          title
        }
        userErrors {
          field
          message
        }
      }
    }
  GRAPHQL

  def call(input:)
    response = execute(MUTATION, input: input)
    response.data = response.data.productUpdate
    handle_user_errors(response.data)
    response
  end
end
```

Usage:

```rb
response = UpdateProduct.call(input: { id: "gid://shopify/Product/123", title: "New title" })
puts response.data.product.title
```
</details>

### Graphql call without wrapper

<details><summary>Click to expand</summary>

```rb
PRODUCT_UPDATE_MUTATION = <<~GRAPHQL
  mutation($input: ProductInput!) {
    productUpdate(input: $input) {
      product {
        id
        title
      }
      userErrors {
        field
        message
      }
    }
  }
GRAPHQL

response = ShopifyGraphql.execute(
  PRODUCT_UPDATE_MUTATION,
  input: { id: "gid://shopify/Product/12345", title: "New title" }
)
response = response.data.productUpdate
ShopifyGraphql.handle_user_errors(response)
```
</details>

## Built-in Graphql calls

- `ShopifyGraphql::CurrentShop`:

  Equivalent to `ShopifyAPI::Shop.current`. Usage example:

  ```rb
  shop = ShopifyGraphql::CurrentShop.call
  puts shop.name
  ```

  Or with locales (requires `read_locales` scope):

  ```rb
  shop = ShopifyGraphql::CurrentShop.call(with_locales: true)
  puts shop.primary_locale
  puts shop.shop_locales
  ```

  Or with products count (requires `read_products` scope):

  ```rb
  shop = ShopifyGraphql::CurrentShop.call(with_products_count: true)
  puts shop.products_count
  ```

  `plan_name` and `plan_display_name` are deprecated and will be removed in v3.0. They're derived from the deprecated `plan.displayName` field. Use `plan_public_display_name`, `plan_shopify_plus` and `plan_partner_development` instead.

- `ShopifyGraphql::CancelSubscription`
- `ShopifyGraphql::CreateRecurringSubscription`
- `ShopifyGraphql::CreateUsageSubscription`
- `ShopifyGraphql::GetAppSubscription`
- `ShopifyGraphql::UpsertPrivateMetafield` (deprecated, see [Deprecated in 2.6](#deprecated-in-26-removed-in-30))
- `ShopifyGraphql::DeletePrivateMetafield` (deprecated, see [Deprecated in 2.6](#deprecated-in-26-removed-in-30))
- `ShopifyGraphql::CreateBulkMutation`
- `ShopifyGraphql::CreateBulkQuery`
- `ShopifyGraphql::CreateStagedUploads`
- `ShopifyGraphql::GetBulkOperation`

Built-in wrappers are located in [`app/graphql/shopify_graphql`](/app/graphql/shopify_graphql/) folder. You can use them directly in your apps or as an example to create your own wrappers.

## Rate limits

The gem exposes Graphql rate limit extensions in response object:

- `points_left`
- `points_limit`
- `points_restore_rate`
- `query_cost`
- `requested_query_cost`

And adds a helper to check if available points lower than threshold (useful for implementing API backoff):

- `points_maxed?(threshold: 100)`

Usage example:

```rb
response = GetProduct.call(id: "gid://shopify/Product/PRODUCT_GID")
response.points_left # => 1999
response.points_limit # => 2000.0
response.points_restore_rate # => 100.0
response.query_cost # => 1
response.points_maxed?(threshold: 100) # => false
```

## Error handling

Failed calls raise `ShopifyGraphql::ConnectionError` or one of its subclasses. GraphQL errors come back with HTTP 200 and are mapped by the first error's `extensions.code`:

| Class | Raised for |
| --- | --- |
| `TooManyRequests` | `THROTTLED`, HTTP 429 and 430 |
| `ServerError` | `INTERNAL_SERVER_ERROR`, HTTP 5xx, invalid JSON and network errors |
| `AccessDenied` | `ACCESS_DENIED` (missing access scope) |
| `MaxCostExceeded` | `MAX_COST_EXCEEDED` (query is over the single query cost limit) |
| `ShopInactive` | `SHOP_INACTIVE` |
| `ShopPendingTermination` | `SHOP_PENDING_TERMINATION` |
| `BadRequest` | HTTP 400 |
| `UnauthorizedAccess` | HTTP 401 |
| `PaymentRequired` | HTTP 402 (shop is frozen) |
| `ForbiddenAccess` | HTTP 403 (shop is marked as fraudulent) |
| `NonExpiringTokenRejected` | HTTP 403 for a public app's non-expiring offline access token, from January 1, 2027. Subclass of `ForbiddenAccess` |
| `ResourceNotFound` | HTTP 404 |
| `MethodNotAllowed`, `ResourceConflict`, `ResourceGone`, `PreconditionFailed` | HTTP 405, 409, 410, 412 |
| `ShopLocked` | HTTP 423 |
| `ClientError` | Other HTTP 4xx |
| `UserError` | `userErrors`, from `handle_user_errors` |
| `ConnectionError` | Other GraphQL error codes |

Everything except `ServerError`, `UserError` and plain `ConnectionError` is a `ClientError`.

Errors raised from a GraphQL response carry its partial `data`, all of its `errors`, and the same cost readers as the response (`query_cost`, `requested_query_cost`, `points_left`, `points_limit`, `points_restore_rate`). `errors` is always an Array, empty when there are none. `data` and the cost readers return `nil` when the information isn't available, e.g. for HTTP and network errors.

```rb
retries = 0
begin
  response = GetProduct.call(id: "gid://shopify/Product/PRODUCT_GID")
rescue ShopifyGraphql::TooManyRequests => error
  retries += 1
  raise if retries > 3

  # Throttled queries don't run, so there's no query_cost. Wait until the requested
  # cost is restored, or 1 second if the response has no cost data.
  wait = 1.0
  if error.requested_query_cost && error.points_left && error.points_restore_rate
    wait = (error.requested_query_cost - error.points_left) / error.points_restore_rate.to_f
  end
  sleep(wait.clamp(1, 60))
  retry
rescue ShopifyGraphql::ConnectionError => error
  error.data   # => partial data, e.g. when a field returns ACCESS_DENIED
  error.errors # => all GraphQL errors
  raise
end
```

`UserError` carries the mutation payload as `data`, its `userErrors` as `errors`, and the cost of the mutation:

```rb
begin
  UpdateProduct.call(input: { id: "gid://shopify/Product/123", title: "" })
rescue ShopifyGraphql::UserError => error
  error.query_cost            # => 10
  error.errors.map(&:message) # => ["Title can't be blank"]
end
```

Wrappers that include `ShopifyGraphql::Query` or `ShopifyGraphql::Mutation` attach the cost automatically. `ShopifyGraphql.execute` and `ShopifyGraphql.handle_user_errors` use a new client on each call, so pass the response explicitly:

```rb
response = ShopifyGraphql.execute(PRODUCT_UPDATE_MUTATION, input: input)
ShopifyGraphql.handle_user_errors(response.data.productUpdate, response: response)
```

### Unavailable shops

`UnauthorizedAccess`, `PaymentRequired`, `ShopLocked`, `ShopPendingTermination` and `ShopInactive` include `ShopifyGraphql::ShopUnavailable`. Rescue it to stop working with a shop that uninstalled the app or was frozen, locked or closed:

```rb
class SyncProductsJob < ApplicationJob
  discard_on ShopifyGraphql::ShopUnavailable

  def perform(shop)
    shop.with_shopify_session do
      GetProducts.call
    end
  end
end
```

Shopify also returns 401 for an expired access token. If you use expiring offline access tokens, a 401 can mean the token wasn't refreshed, so refresh it before treating the shop as uninstalled.

`ForbiddenAccess`, `NonExpiringTokenRejected` and `ResourceNotFound` aren't included, so handle them separately. A 403 means the shop was marked as fraudulent or, from January 1, 2027, that the app sent a non-expiring access token, which would affect every shop at once. A 404 is also raised for null nodes.

## Custom apps

In custom apps, if you're using `shopify_app` gem, then the setup is similar public apps. Except `Shop` model which must include class method to make queries to your store:

```rb
# app/models/shop.rb
class Shop < ActiveRecord::Base
  include ShopifyApp::ShopSessionStorageWithScopes

  def self.system
    new(
      shopify_domain: "MYSHOPIFY_DOMAIN",
      shopify_token: "API_ACCESS_TOKEN_FOR_CUSTOM_APP"
    )
  end
end
```

Using this method, you should be able to make API calls like this:

```rb
Shop.system.with_shopify_session do
  GetOrder.call(id: order.shopify_gid)
end
```

If you're not using `shopify_app` gem, then you need to setup `ShopifyAPI::Context` manually:

```rb
# config/initializers/shopify_api.rb
ShopifyAPI::Context.setup(
  api_key: "XXX",
  api_secret_key: "XXXX",
  scope: "read_orders,read_products",
  is_embedded: false,
  api_version: "2024-07",
  is_private: true,
)
```

And create another method in Shop model to make queries to your store:

```rb
# app/models/shop.rb
def Shop
  def self.with_shopify_session(&block)
    ShopifyAPI::Auth::Session.temp(
      shop: "MYSHOPIFY_DOMAIN",
      access_token: "API_ACCESS_TOKEN_FOR_CUSTOM_APP",
      &block
    )
  end
end
```

Using this method, you should be able to make API calls like this:

```rb
Shop.with_shopify_session do
  GetOrder.call(id: order.shopify_gid)
end
```

## Deprecated in 2.6, removed in 3.0

These APIs warn through `ShopifyGraphql.deprecator`, once per process for each API. On Rails 7.1+ it's registered as `Rails.application.deprecators[:shopify_graphql]`, so your `config.active_support.deprecation` settings apply to it.

| Deprecated | Use instead |
| --- | --- |
| `ShopifyGraphql::UpsertPrivateMetafield`, `ShopifyGraphql::DeletePrivateMetafield` | App-owned metafields: `metafieldsSet` and `metafieldsDelete` with an `$app` namespace. Shopify has removed `privateMetafieldUpsert` and `privateMetafieldDelete` from the Admin API. |
| [Graphql webhooks](#graphql-webhooks-deprecated): `ShopifyGraphql::WebhooksManager`, `ShopifyGraphql::Webhook`, `CreateWebhooksJob`, `DestroyWebhooksJob`, `UpdateWebhooksJob`, `WebhookVerification`, the `graphql_webhooks` route and the `config.webhook*` options | `shopify_app` [webhooks](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/webhooks.md) or app-specific subscriptions in `shopify.app.toml` |
| `ShopifyGraphql::Resource`, `ShopifyGraphql::Shop.current` | `ShopifyGraphql::CurrentShop`, or your own classes that include `ShopifyGraphql::Query` or `ShopifyGraphql::Mutation` |
| `ShopifyGraphql::PLAN_TO_DISPLAY_NAME`, `ShopifyGraphql::DISPLAY_NAME_TO_PLAN`, `ShopifyGraphql.normalize_plan_display_name` | `plan_public_display_name`, `plan_shopify_plus` and `plan_partner_development` from `ShopifyGraphql::CurrentShop` |
| `plan_name` and `plan_display_name` from `ShopifyGraphql::CurrentShop` (no runtime warning) | `plan_public_display_name`, `plan_shopify_plus` and `plan_partner_development` |

## Graphql webhooks (deprecated)

> [!WARNING]
> ShopifyGraphql webhooks are deprecated and will be removed in v3.0. Please use `shopify_app` gem for handling webhooks or declare app-specific subscriptions in `shopify.app.toml`. See [`shopify_app` documentation](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/webhooks.md) for more details.

The gem has built-in support for Graphql webhooks (similar to `shopify_app`). To enable it add the following config to `config/initializers/shopify_app.rb`:

```rb
ShopifyGraphql.configure do |config|
  # Webhooks
  webhooks_prefix = "https://#{Rails.configuration.app_host}/graphql_webhooks"
  config.webhook_jobs_namespace = 'shopify/webhooks'
  config.webhook_enabled_environments = ['development', 'staging', 'production']
  config.webhooks = [
    { topic: 'SHOP_UPDATE', address: "#{webhooks_prefix}/shop_update" },
    { topic: 'APP_SUBSCRIPTIONS_UPDATE', address: "#{webhooks_prefix}/app_subscriptions_update" },
    { topic: 'APP_UNINSTALLED', address: "#{webhooks_prefix}/app_uninstalled" },
  ]
end
```

And add the following routes to `config/routes.rb`:

```rb
mount ShopifyGraphql::Engine, at: '/'
```

To register defined webhooks you need to call `ShopifyGraphql::UpdateWebhooksJob`. You can call it manually or use `AfterAuthenticateJob` from `shopify_app`:

```rb
# config/initializers/shopify_app.rb
ShopifyApp.configure do |config|
  # ...
  config.after_authenticate_job = {job: "AfterAuthenticateJob", inline: true}
end
```

```rb
# app/jobs/after_install_job.rb
class AfterInstallJob < ApplicationJob
  def perform(shop)
    # ...
    update_webhooks(shop)
  end

  def update_webhooks(shop)
    ShopifyGraphql::UpdateWebhooksJob.perform_later(
      shop_domain: shop.shopify_domain,
      shop_token: shop.shopify_token
    )
  end
end
```

To handle webhooks create jobs in `app/jobs/webhooks` folder. The gem will automatically call them when new webhooks are received. The job name should match the webhook topic name. For example, to handle `APP_UNINSTALLED` webhook create `app/jobs/webhooks/app_uninstalled_job.rb`:

```rb
class Webhooks::AppUninstalledJob < ApplicationJob
  queue_as :default

  def perform(shop_domain:, webhook:)
    shop = Shop.find_by!(shopify_domain: shop_domain)
    # handle shop uninstall
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
