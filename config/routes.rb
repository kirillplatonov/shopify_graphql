ShopifyGraphQL::Engine.routes.draw do
  namespace :webhooks do
    post ':type' => :receive
  end
end
