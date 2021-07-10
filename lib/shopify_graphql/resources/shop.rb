module ShopifyGraphql
  class Shop < BaseResource
    class << self
      def current
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
