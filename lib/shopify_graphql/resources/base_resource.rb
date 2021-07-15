module ShopifyGraphQL
  class BaseResource
    class << self
      delegate :execute, :handle_user_errors, to: :client

      def client
        ShopifyGraphQL::Client.new
      end
    end
  end
end
