module ShopifyGraphQL
  module Resource
    extend ActiveSupport::Concern

    class_methods do
      delegate :execute, :handle_user_errors, to: :client

      def client
        ShopifyGraphQL::Client.new
      end
    end
  end
end
