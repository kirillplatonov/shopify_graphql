Rails.application.routes.draw do
  mount ShopifyGraphql::Engine, at: "/"
end
