module ShopifyGraphQL
  class Shop
    extend GQLi::DSL

    class << self
      def current
        Client.new.execute(
          query {
            shop {
              id
              name
              myshopifyDomain
              description
              plan { displayName }
            }
          }
        )
      end
    end
  end
end
