module ShopifyGraphql::Mutation
  extend ActiveSupport::Concern

  class_methods do
    def call(**kwargs)
      new.call(**kwargs)
    end
  end

  delegate :execute, :handle_user_errors, to: :client

  def client
    @client ||= ShopifyGraphql::Client.new
  end
end
