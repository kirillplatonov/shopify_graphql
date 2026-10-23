module ShopifyGraphql
  class CurrentShop
    include ShopifyGraphql::Query

    QUERY = <<~GRAPHQL
      query {
        shop {
          id
          name
          email
          contactEmail
          myshopifyDomain
          primaryDomain {
            host
          }
          createdAt
          updatedAt
          shopOwnerName
          currencyCode
          shopAddress {
            country
            countryCodeV2
            province
            provinceCode
            city
            address1
            address2
            zip
            latitude
            longitude
            phone
          }
          timezoneAbbreviation
          ianaTimezone
          plan {
            displayName
            publicDisplayName
            shopifyPlus
            partnerDevelopment
          }
          currencyFormats {
            moneyFormat
            moneyInEmailsFormat
            moneyWithCurrencyFormat
            moneyWithCurrencyInEmailsFormat
          }
          weightUnit
          taxShipping
          taxesIncluded
          setupRequired
          checkoutApiSupported
          transactionalSmsDisabled
          enabledPresentmentCurrencies
          marketingSmsConsentEnabledAtCheckout
          resourceLimits {
            maxProductOptions
            maxProductVariants
          }
        }
        currentAppInstallation {
          id
        }
        onlineStore {
          passwordProtection {
            enabled
          }
        }
        #LOCALES_SUBQUERY#
        #PRODUCTS_COUNT_SUBQUERY#
      }
    GRAPHQL
    LOCALES_SUBQUERY = <<~GRAPHQL
      shopLocales {
        locale
        primary
      }
    GRAPHQL
    PRODUCTS_COUNT_SUBQUERY = <<~GRAPHQL
      productsCount {
        count
      }
    GRAPHQL

    def call(with_locales: false, with_products_count: false)
      query = prepare_query(QUERY, with_locales: with_locales, with_products_count: with_products_count)
      response = execute(query)
      parse_data(response, with_locales: with_locales, with_products_count: with_products_count)
    end

    private

    def prepare_query(query, with_locales:, with_products_count: false)
      query = query.gsub("#LOCALES_SUBQUERY#", with_locales ? LOCALES_SUBQUERY : "")
      query.gsub("#PRODUCTS_COUNT_SUBQUERY#", with_products_count ? PRODUCTS_COUNT_SUBQUERY : "")
    end

    def parse_data(response, with_locales: false, with_products_count: false)
      data = response.data
      plan_display_name = ShopifyGraphql.normalize_plan_display_name(data.shop.plan.displayName)
      plan_name = ShopifyGraphql::DISPLAY_NAME_TO_PLAN[plan_display_name]
      shop_data = OpenStruct.new(
        id: data.shop.id.split("/").last.to_i,
        name: data.shop.name,
        email: data.shop.email,
        customer_email: data.shop.contactEmail,
        myshopify_domain: data.shop.myshopifyDomain,
        domain: data.shop.primaryDomain.host,
        created_at: data.shop.createdAt,
        updated_at: data.shop.updatedAt,
        shop_owner: data.shop.shopOwnerName,
        currency: data.shop.currencyCode,
        country_name: data.shop.shopAddress.country,
        country: data.shop.shopAddress.countryCodeV2,
        country_code: data.shop.shopAddress.countryCodeV2,
        province: data.shop.shopAddress.province,
        province_code: data.shop.shopAddress.provinceCode,
        city: data.shop.shopAddress.city,
        address1: data.shop.shopAddress.address1,
        address2: data.shop.shopAddress.address2,
        zip: data.shop.shopAddress.zip,
        latitude: data.shop.shopAddress.latitude,
        longitude: data.shop.shopAddress.longitude,
        phone: data.shop.shopAddress.phone,
        timezone: data.shop.timezoneAbbreviation,
        iana_timezone: data.shop.ianaTimezone,
        plan_name: plan_name,
        plan_display_name: plan_display_name,
        plan_public_display_name: data.shop.plan.publicDisplayName,
        plan_shopify_plus: data.shop.plan.shopifyPlus,
        plan_partner_development: data.shop.plan.partnerDevelopment,
        money_format: data.shop.currencyFormats.moneyFormat,
        money_in_emails_format: data.shop.currencyFormats.moneyInEmailsFormat,
        money_with_currency_format: data.shop.currencyFormats.moneyWithCurrencyFormat,
        money_with_currency_in_emails_format: data.shop.currencyFormats.moneyWithCurrencyInEmailsFormat,
        weight_unit: data.shop.weightUnit,
        tax_shipping: data.shop.taxShipping,
        taxes_included: data.shop.taxesIncluded,
        setup_required: data.shop.setupRequired,
        checkout_api_supported: data.shop.checkoutApiSupported,
        transactional_sms_disabled: data.shop.transactionalSmsDisabled,
        enabled_presentment_currencies: data.shop.enabledPresentmentCurrencies,
        marketing_sms_consent_enabled_at_checkout: data.shop.marketingSmsConsentEnabledAtCheckout,
        max_product_options: data.shop.resourceLimits.maxProductOptions,
        max_product_variants: data.shop.resourceLimits.maxProductVariants,
        unified_markets: true,
        app_installation_id: data.currentAppInstallation&.id,
        password_enabled: !!data.onlineStore&.passwordProtection&.enabled,
        products_count: with_products_count ? data.productsCount&.count : nil,
        graphql_points_limit: response.points_limit
      )
      if with_locales
        shop_data.primary_locale = data.shopLocales.find(&:primary).locale
        shop_data.shop_locales = data.shopLocales.map(&:locale)
      end
      shop_data
    end
  end
end
