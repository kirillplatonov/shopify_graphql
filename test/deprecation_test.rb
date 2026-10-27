require "test_helper"
require "open3"

class DeprecationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  SHOP_ARGS = { shop_domain: "test-shop.myshopify.com", shop_token: "test-token" }

  test "deprecator is defined and loading the gem emits no warnings without Rails" do
    script = 'require "shopify_graphql"; print defined?(Rails).inspect, " ", ShopifyGraphql.deprecator.class'
    lib = File.expand_path("../lib", __dir__)
    out, err, status = Open3.capture3(RbConfig.ruby, "-rbundler/setup", "-I", lib, "-e", script)

    assert status.success?, err
    assert_equal "nil ActiveSupport::Deprecation", out
    assert_not_includes err, "DEPRECATION WARNING"
  end

  test "deprecator is registered with the app" do
    skip "Rails < 7.1" unless Rails.application.respond_to?(:deprecators)

    assert_same ShopifyGraphql.deprecator, Rails.application.deprecators[:shopify_graphql]
  end

  test "warning points at the caller outside the gem" do
    warnings = collect_deprecations(ShopifyGraphql.deprecator) { ShopifyGraphql::PLAN_TO_DISPLAY_NAME }.last

    assert_match "called from", warnings.first
    assert_includes warnings.first, __FILE__
  end

  test "UpsertPrivateMetafield" do
    variables = { input: { namespace: "NAMESPACE", key: "KEY", valueInput: { value: "VALUE", valueType: "STRING" } } }
    fake("mutations/upsert_private_method_shop.json", ShopifyGraphql::UpsertPrivateMetafield::MUTATION, **variables)

    assert_deprecated_once("ShopifyGraphql::UpsertPrivateMetafield is deprecated") do
      ShopifyGraphql::UpsertPrivateMetafield.call(namespace: "NAMESPACE", key: "KEY", value: "VALUE")
    end
  end

  test "DeletePrivateMetafield" do
    variables = { input: { namespace: "NAMESPACE", key: "KEY" } }
    fake("mutations/delete_private_method_shop.json", ShopifyGraphql::DeletePrivateMetafield::MUTATION, **variables)

    assert_deprecated_once("ShopifyGraphql::DeletePrivateMetafield is deprecated") do
      ShopifyGraphql::DeletePrivateMetafield.call(namespace: "NAMESPACE", key: "KEY")
    end
  end

  { create: "CreateWebhooksJob", destroy: "DestroyWebhooksJob", update: "UpdateWebhooksJob" }.each do |action, job|
    test "WebhooksManager.queue_#{action}" do
      assert_deprecated_once("ShopifyGraphql::WebhooksManager.queue_#{action} is part of ShopifyGraphql webhooks") do
        ShopifyGraphql::WebhooksManager.public_send("queue_#{action}", *SHOP_ARGS.values)
      end
      assert_enqueued_with(job: "ShopifyGraphql::#{job}".constantize, args: [SHOP_ARGS])
    end

    test job do
      assert_deprecated_once("ShopifyGraphql::#{job} is part of ShopifyGraphql webhooks") do
        "ShopifyGraphql::#{job}".constantize.perform_now(**SHOP_ARGS)
      end
    end
  end

  test "WebhooksManager instance" do
    assert_deprecated_once("ShopifyGraphql::WebhooksManager is part of ShopifyGraphql webhooks") do
      ShopifyGraphql::WebhooksManager.new([])
    end
  end

  test "Webhook" do
    stub_request(:post, API_PATH).to_return(body: { data: { webhookSubscriptions: { edges: [] } } }.to_json)

    assert_deprecated_once("ShopifyGraphql::Webhook is part of ShopifyGraphql webhooks") do
      assert_equal [], ShopifyGraphql::Webhook.all
    end
  end

  test "WebhookVerification" do
    controller = ShopifyGraphql::GraphqlWebhooksController.new

    assert_deprecated_once("ShopifyGraphql::WebhookVerification is part of ShopifyGraphql webhooks") do
      controller.send(:deprecate_webhooks)
    end
  end

  test "Configuration#webhooks=" do
    config = ShopifyGraphql::Configuration.new
    webhooks = [{ topic: "SHOP_UPDATE", address: "https://example.com/graphql_webhooks/shop_update" }]

    assert_deprecated_once("ShopifyGraphql::Configuration#webhooks= is part of ShopifyGraphql webhooks") do
      config.webhooks = webhooks
    end
    assert_equal webhooks, config.webhooks
    assert config.has_webhooks?
  end

  test "Configuration#webhook_jobs_namespace=" do
    config = ShopifyGraphql::Configuration.new

    assert_deprecated_once("ShopifyGraphql::Configuration#webhook_jobs_namespace= is part of ShopifyGraphql webhooks") do
      config.webhook_jobs_namespace = "shopify/webhooks"
    end
    assert_equal "shopify/webhooks", config.webhook_jobs_namespace
  end

  test "Configuration setters with blank values don't warn" do
    config = ShopifyGraphql::Configuration.new

    assert_not_deprecated(ShopifyGraphql.deprecator) do
      config.webhooks = []
      config.webhooks = nil
      config.webhook_jobs_namespace = nil
      config.webhook_jobs_namespace = ""
    end
  end

  test "Resource" do
    assert_deprecated_once("ShopifyGraphql::Resource is deprecated") do
      Class.new { include ShopifyGraphql::Resource }
    end
  end

  test "Resource doesn't warn for the gem's own resources" do
    assert_not_deprecated(ShopifyGraphql.deprecator) do
      Class.new do
        def self.name = "ShopifyGraphql::Shop"
        include ShopifyGraphql::Resource
      end
    end
  end

  test "Shop.current" do
    stub_request(:post, API_PATH).to_return(body: File.read(File.expand_path("fixtures/queries/shop.json", __dir__)))

    assert_deprecated_once("ShopifyGraphql::Shop.current is deprecated") do
      assert_equal "Graphql Gem Test", ShopifyGraphql::Shop.current.data.shop.name
    end
  end

  test "PLAN_TO_DISPLAY_NAME" do
    plan_names = ShopifyGraphql.const_get(:PlanNames)

    assert_deprecated_once("ShopifyGraphql::PLAN_TO_DISPLAY_NAME is deprecated") do
      assert_same plan_names::PLAN_TO_DISPLAY_NAME, ShopifyGraphql::PLAN_TO_DISPLAY_NAME
    end
    assert_equal 20, ShopifyGraphql::PLAN_TO_DISPLAY_NAME.size
    assert_equal "developer_preview", ShopifyGraphql::PLAN_TO_DISPLAY_NAME["partner_test"]
    assert_equal "shopify", ShopifyGraphql::PLAN_TO_DISPLAY_NAME["professional"]
  end

  test "DISPLAY_NAME_TO_PLAN" do
    plan_names = ShopifyGraphql.const_get(:PlanNames)

    assert_deprecated_once("ShopifyGraphql::DISPLAY_NAME_TO_PLAN is deprecated") do
      assert_same plan_names::DISPLAY_NAME_TO_PLAN, ShopifyGraphql::DISPLAY_NAME_TO_PLAN
    end
    assert_equal plan_names::PLAN_TO_DISPLAY_NAME.invert, ShopifyGraphql::DISPLAY_NAME_TO_PLAN
    assert_equal "partner_test", ShopifyGraphql::DISPLAY_NAME_TO_PLAN["developer_preview"]
  end

  test "normalize_plan_display_name" do
    assert_deprecated_once("ShopifyGraphql.normalize_plan_display_name is deprecated") do
      assert_equal "developer_preview", ShopifyGraphql.normalize_plan_display_name("Developer Preview")
    end
    assert_nil ShopifyGraphql.normalize_plan_display_name("")
  end

  test "other missing constants still raise" do
    assert_raises(NameError) { ShopifyGraphql::MissingConstant }
  end

  private

  def assert_deprecated_once(match, &block)
    assert_deprecated(match, ShopifyGraphql.deprecator, &block)
    assert_not_deprecated(ShopifyGraphql.deprecator, &block)
  end
end
