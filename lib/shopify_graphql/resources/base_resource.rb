module ShopifyGraphql
  class BaseResource
    class << self
      delegate :execute, :handle_user_errors, to: :client

      def client
        ShopifyGraphql::Client.new
      end
    end
  end
end
