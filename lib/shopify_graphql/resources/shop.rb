module ShopifyGraphql
  class Shop
    include Resource

    class << self
      def current
        ShopifyGraphql::Deprecation.warn_once("ShopifyGraphql::Shop.current", "ShopifyGraphql::Shop.current is deprecated and will be removed in v3.0. " \
          "Please use ShopifyGraphql::CurrentShop or your own ShopifyGraphql::Query class instead.")
        execute <<~GRAPHQL
          query {
            shop {
              id
              name
              myshopifyDomain
              description
              plan { displayName }
            }
          }
        GRAPHQL
      end
    end
  end
end
