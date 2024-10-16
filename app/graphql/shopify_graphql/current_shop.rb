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
          #SHOP_OWNER_NAME#
          currencyCode
          billingAddress {
            country
            countryCodeV2
            province
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
        }
        #LOCALES_SUBQUERY#
      }
    GRAPHQL
    LOCALES_SUBQUERY = <<~GRAPHQL
      shopLocales {
        locale
        primary
      }
    GRAPHQL

    def call(with_locales: false)
      query = QUERY
      query.gsub!("#LOCALES_SUBQUERY#", with_locales ? LOCALES_SUBQUERY : "")
      if ShopifyAPI::Context.api_version.in?(%w[2024-01 2024-04 2024-07])
        query.gsub!("#SHOP_OWNER_NAME#", "")
      else
        query.gsub!("#SHOP_OWNER_NAME#", "shopOwnerName")
      end
      response = execute(query)
      parse_data(response.data, with_locales: with_locales)
    end

    private

    def parse_data(data, with_locales: false)
      plan_display_name = ShopifyGraphql.normalize_plan_display_name(data.shop.plan.displayName)
      plan_name = ShopifyGraphql::DISPLAY_NAME_TO_PLAN[plan_display_name]
      response = OpenStruct.new(
        id: data.shop.id,
        name: data.shop.name,
        email: data.shop.email,
        customer_email: data.shop.contactEmail,
        myshopify_domain: data.shop.myshopifyDomain,
        domain: data.shop.primaryDomain.host,
        created_at: data.shop.createdAt,
        updated_at: data.shop.updatedAt,
        shop_owner: data.shop.shopOwnerName,
        currency: data.shop.currencyCode,
        country_name: data.shop.billingAddress.country,
        country: data.shop.billingAddress.countryCodeV2,
        country_code: data.shop.billingAddress.countryCodeV2,
        province: data.shop.billingAddress.province,
        province_code: data.shop.billingAddress.provinceCode,
        city: data.shop.billingAddress.city,
        address1: data.shop.billingAddress.address1,
        address2: data.shop.billingAddress.address2,
        zip: data.shop.billingAddress.zip,
        latitude: data.shop.billingAddress.latitude,
        longitude: data.shop.billingAddress.longitude,
        phone: data.shop.billingAddress.phone,
        timezone: data.shop.timezoneAbbreviation,
        iana_timezone: data.shop.ianaTimezone,
        plan_name: plan_name,
        plan_display_name: plan_display_name,
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
        marketing_sms_consent_enabled_at_checkout: data.shop.marketingSmsConsentEnabledAtCheckout
      )
      if with_locales
        response.primary_locale = data.shopLocales.find(&:primary).locale
        response.shop_locales = data.shopLocales.map(&:locale)
      end
      response
    end
  end
end
