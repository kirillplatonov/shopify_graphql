module ShopifyGraphql
  # Maps plan.displayName to the legacy plan_name for CurrentShop. The public
  # ShopifyGraphql::PLAN_TO_DISPLAY_NAME and DISPLAY_NAME_TO_PLAN below are deprecated.
  module PlanNames # :nodoc:
    # Mapping from deprecated plan_name to plan_display_name
    PLAN_TO_DISPLAY_NAME = {
      "trial" => "trial",
      "frozen" => "frozen",
      "fraudulent" => "cancelled",
      "shopify_alumni" =>	"shopify_alumni",
      "affiliate" => "development",
      "basic" => "basic",
      "professional" => "shopify",
      "npo_full" => "npo_full",
      "shopify_plus" => "shopify_plus",
      "staff" => "staff",
      "unlimited" => "advanced",
      "retail" => "retail",
      "cancelled" => "cancelled",
      "dormant" => "pause_and_build",
      "starter_2022" => "shopify_starter",
      "plus_partner_sandbox" => "shopify_plus_partner_sandbox",
      "paid_trial" => "extended_trial",
      "partner_test" => "developer_preview",
      "open_learning" => "open_learning",
      "staff_business" => "staff_business"
    }
    DISPLAY_NAME_TO_PLAN = PLAN_TO_DISPLAY_NAME.invert

    def self.normalize_display_name(plan_display_name)
      return if plan_display_name.blank?
      plan_display_name.parameterize(separator: "_")
    end
  end

  PLAN_TO_DISPLAY_NAME = Deprecation::ConstantProxy.new(
    "ShopifyGraphql::PLAN_TO_DISPLAY_NAME", "ShopifyGraphql::PlanNames::PLAN_TO_DISPLAY_NAME", deprecator,
    message: "ShopifyGraphql::PLAN_TO_DISPLAY_NAME is deprecated and will be removed in v3.0. #{Deprecation::PLAN_MESSAGE}"
  )
  DISPLAY_NAME_TO_PLAN = Deprecation::ConstantProxy.new(
    "ShopifyGraphql::DISPLAY_NAME_TO_PLAN", "ShopifyGraphql::PlanNames::DISPLAY_NAME_TO_PLAN", deprecator,
    message: "ShopifyGraphql::DISPLAY_NAME_TO_PLAN is deprecated and will be removed in v3.0. #{Deprecation::PLAN_MESSAGE}"
  )
end
