module ShopifyGraphql::Query
  extend ActiveSupport::Concern

  class_methods do
    def call(**kwargs, &block)
      new.call(**kwargs, &block)
    end
  end

  delegate :execute, :handle_user_errors, to: :client

  def client
    @client ||= ShopifyGraphql::Client.new
  end
end
