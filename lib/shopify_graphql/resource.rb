module ShopifyGraphql
  module Resource
    extend ActiveSupport::Concern

    class_methods do
      extend Forwardable
      def_delegators :client, :execute, :handle_user_errors

      def client
        ShopifyGraphql::Client.new
      end
    end
  end
end
