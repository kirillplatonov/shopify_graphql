Rails.application.routes.draw do
  mount ShopifyGraphql::Engine => "/shopify_graphql"
end
