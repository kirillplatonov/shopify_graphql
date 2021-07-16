module ShopifyGraphql
  module Resource
    extend ActiveSupport::Concern

    class_methods do
      delegate :execute, :handle_user_errors, to: :client

      def client
        ShopifyGraphql::Client.new
      end
    end
  end
end
