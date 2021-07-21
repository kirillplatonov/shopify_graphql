ShopifyGraphql::Engine.routes.draw do
  namespace :graphql_webhooks do
    post ':type' => :receive
  end
end
