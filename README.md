# Shopify Graphql

Less painful way to work with [Shopify Graphql API](https://shopify.dev/api/admin-graphql) in Ruby. This library is a tiny wrapper on top of [`shopify_api`](https://github.com/Shopify/shopify-api-ruby) gem. It provides a simple API for Graphql calls, better error handling, and Graphql webhooks integration.

## Features

- Simple API for Graphql queries and mutations
- Conventions for organizing Graphql code
- ActiveResource-like error handling
- Graphql and user error handlers
- Auto-conversion of responses to OpenStruct
- Graphql webhooks integration for Rails
- Wrappers for Graphql rate limit extensions
- Built-in calls for common Graphql calls

## Dependencies

- [`shopify_api`](https://github.com/Shopify/shopify-api-ruby) v10+
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

    query {
      products(first: #{LIMIT}) {
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
  QUERY_WITH_CURSOR = <<~GRAPHQL
    #{ProductFields::FRAGMENT}

    query($cursor: String!) {
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
      response = execute(QUERY_WITH_CURSOR, cursor: response.data.products.pageInfo.endCursor)
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

    query {
      products(first: #{LIMIT}) {
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
  QUERY_WITH_CURSOR = <<~GRAPHQL
    #{ProductFields::FRAGMENT}

    query($cursor: String!) {
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
      response = execute(QUERY_WITH_CURSOR, cursor: response.data.products.pageInfo.endCursor)
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
    query {
      collections(first: #{COLLECTIONS_LIMIT}) {
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
  QUERY_WITH_CURSOR = <<~GRAPHQL
    query ($cursor: String!) {
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
      response = execute(QUERY_WITH_CURSOR, cursor: response.data.collections.pageInfo.endCursor)
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

- `ShopifyGraphql::CancelSubscription`
- `ShopifyGraphql::CreateRecurringSubscription`
- `ShopifyGraphql::CreateUsageSubscription`
- `ShopifyGraphql::GetAppSubscription`
- `ShopifyGraphql::UpsertPrivateMetafield`
- `ShopifyGraphql::DeletePrivateMetafield`

Built-in wrappers are located in [`app/graphql/shopify_graphql`](/app/graphql/shopify_graphql/) folder. You can use them directly in your apps or as an example to create your own wrappers.

## Graphql webhooks

> Since version 10 `shopify_api` gem includes built-in support for Graphql webhooks. If you are using `shopify_api` version 10 or higher you don't need to use this gem to handle Graphql webhooks. See [`shopify_app` documentation](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/webhooks.md) for more details.

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
