require "test_helper"

class RedactJobParamsTest < ActiveSupport::TestCase
  class LogSubscriber
    private

    def args_info(job)
      "args"
    end
  end

  setup do
    @subscriber = Class.new(LogSubscriber) { prepend ShopifyGraphql::RedactJobParams }.new
  end

  test "redacts arguments of webhook jobs" do
    assert_equal "", @subscriber.send(:args_info, ShopifyGraphql::CreateWebhooksJob.new)
  end

  test "keeps arguments of jobs whose name is part of a webhook job name" do
    job_class = Class.new do
      def self.name
        "WebhooksJob"
      end
    end

    assert_equal "args", @subscriber.send(:args_info, job_class.new)
  end
end
