# Shopify Graphql

Less painful way to work with [Shopify Graphql API](https://shopify.dev/api/admin/graphql/reference) in Ruby.

> **This library is under active development. Breaking changes are likely until stable release.**

## Features

- Simple API for Graphql calls
- Graphql webhooks integration
- Built-in error handling
- No schema and no memory issues
- (Planned) Testing helpers
- (Planned) Buil-in retry on error
- (Planned) Pre-built calls for common Graphql operations

## Usage

### Making Graphql calls directly

```ruby
CREATE_WEBHOOK_MUTATION = <<~GRAPHQL
  mutation($topic: WebhookSubscriptionTopic!, $webhookSubscription: WebhookSubscriptionInput!) {
    webhookSubscriptionCreate(topic: $topic, webhookSubscription: $webhookSubscription) {
      webhookSubscription {
        id
      }
      userErrors {
        field
        message
      }
    }
  }
GRAPHQL

response = ShopifyGraphql.execute(CREATE_WEBHOOK_MUTATION,
  topic: "TOPIC",
  webhookSubscription: { callbackUrl: "ADDRESS", format: "JSON" },
)
response = response.data.webhookSubscriptionCreate
ShopifyGraphql.handle_user_errors(response)
```

### Creating wrappers for queries, mutations, and fields

To isolate Graphql boilerplate you can create wrappers. To keep them organized use the following conventions:
- Put them all into `app/graphql` folder
- Use `Fields` suffix to name fields (eg `AppSubscriptionFields`)
- Use `Get` prefix to name queries (eg `GetProducts` or `GetAppSubscription`)
- Use imperative to name mutations (eg `CreateUsageSubscription` or `BulkUpdateVariants`)

#### Example fields

Definition:
```ruby
class AppSubscriptionFields
  FRAGMENT = <<~GRAPHQL
    fragment AppSubscriptionFields on AppSubscription {
      id
      name
      status
      trialDays
      currentPeriodEnd
      test
      lineItems {
        id
        plan {
          pricingDetails {
            __typename
            ... on AppRecurringPricing {
              price {
                amount
              }
              interval
            }
            ... on AppUsagePricing {
              balanceUsed {
                amount
              }
              cappedAmount {
                amount
              }
              interval
              terms
            }
          }
        }
      }
    }
  GRAPHQL

  def self.parse(data)
    recurring_line_item = data.lineItems.find { |i| i.plan.pricingDetails.__typename == "AppRecurringPricing" }
    recurring_pricing = recurring_line_item&.plan&.pricingDetails
    usage_line_item = data.lineItems.find { |i| i.plan.pricingDetails.__typename == "AppUsagePricing" }
    usage_pricing = usage_line_item&.plan&.pricingDetails

    OpenStruct.new(
      id: data.id,
      name: data.name,
      status: data.status,
      trial_days: data.trialDays,
      current_period_end: data.currentPeriodEnd && Time.parse(data.currentPeriodEnd),
      test: data.test,
      recurring_line_item_id: recurring_line_item&.id,
      recurring_price: recurring_pricing&.price&.amount&.to_d,
      recurring_interval: recurring_pricing&.interval,
      usage_line_item_id: usage_line_item&.id,
      usage_balance: usage_pricing&.balanceUsed&.amount&.to_d,
      usage_capped_amount: usage_pricing&.cappedAmount&.amount&.to_d,
      usage_interval: usage_pricing&.interval,
      usage_terms: usage_pricing&.terms,
    )
  end
end
```

For usage examples see query and mutation below.

#### Example query

Definition:
```ruby
class GetAppSubscription
  include ShopifyGraphql::Query

  QUERY = <<~GRAPHQL
    #{AppSubscriptionFields::FRAGMENT}
    query($id: ID!) {
      node(id: $id) {
        ... AppSubscriptionFields
      }
    }
  GRAPHQL

  def call(id:)
    response = execute(QUERY, id: id)
    response.data = AppSubscriptionFields.parse(response.data.node)
    response
  end
end
```

Usage:
```ruby
shopify_subscription = GetAppSubscription.call(id: @id).data
shopify_subscription.status
shopify_subscription.current_period_end
```

#### Example mutation

Definition:
```ruby
class CreateRecurringSubscription
  include ShopifyGraphql::Mutation

  MUTATION = <<~GRAPHQL
    #{AppSubscriptionFields::FRAGMENT}
    mutation appSubscriptionCreate(
      $name: String!,
      $lineItems: [AppSubscriptionLineItemInput!]!,
      $returnUrl: URL!,
      $trialDays: Int,
      $test: Boolean
    ) {
      appSubscriptionCreate(
        name: $name,
        lineItems: $lineItems,
        returnUrl: $returnUrl,
        trialDays: $trialDays,
        test: $test
      ) {
        appSubscription {
          ... AppSubscriptionFields
        }
        confirmationUrl
        userErrors {
          field
          message
        }
      }
    }
  GRAPHQL

  def call(name:, price:, return_url:, trial_days: nil, test: nil, interval: :monthly)
    payload = { name: name, returnUrl: return_url }
    plan_interval = (interval == :monthly) ? 'EVERY_30_DAYS' : 'ANNUAL'
    payload[:lineItems] = [{
      plan: {
        appRecurringPricingDetails: {
          price: { amount: price, currencyCode: 'USD' },
          interval: plan_interval
        }
      }
    }]
    payload[:trialDays] = trial_days if trial_days
    payload[:test] = test if test

    response = execute(MUTATION, **payload)
    response.data = response.data.appSubscriptionCreate
    handle_user_errors(response.data)
    response.data = parse_data(response.data)
    response
  end

  private

  def parse_data(data)
    OpenStruct.new(
      subscription: AppSubscriptionFields.parse(data.appSubscription),
      confirmation_url: data.confirmationUrl,
    )
  end
end
```

Usage:
```ruby
response = CreateRecurringSubscription.call(
  name: "Plan Name",
  price: 10,
  return_url: "RETURN URL",
  trial_days: 3,
  test: true,
).data
confirmation_url = response.confirmation_url
shopify_subscription = response.subscription
```

## Installation

In Gemfile, add:
```
gem 'shopify_graphql', github: 'kirillplatonov/shopify_graphql', branch: 'main'
```

This gem relies on `shopify_app` for authentication so no extra setup is required. But you still need to wrap your Graphql calls with `shop.with_shopify_session`:
```ruby
shop.with_shopify_session do
  # your calls to graphql
end
```

The gem has built-in support for graphql webhooks (similar to `shopify_app`). To enable it add the following config to `config/initializers/shopify_app.rb`:
```ruby
ShopifyGraphql.configure do |config|
  # Webhooks
  webhooks_prefix = "https://#{Rails.configuration.app_host}/graphql_webhooks"
  config.webhook_jobs_namespace = 'shopify/webhooks'
  config.webhook_enabled_environments = ['production']
  config.webhooks = [
    { topic: 'SHOP_UPDATE', address: "#{webhooks_prefix}/shop_update" },
    { topic: 'APP_SUBSCRIPTIONS_UPDATE', address: "#{webhooks_prefix}/app_subscriptions_update" },
    { topic: 'APP_UNINSTALLED', address: "#{webhooks_prefix}/app_uninstalled" },
  ]
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
