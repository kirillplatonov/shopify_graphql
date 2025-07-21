require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  setup do
    # Store the original configuration to restore it later
    @original_config = ShopifyGraphql.configuration.convert_case
  end

  teardown do
    # Restore original configuration
    ShopifyGraphql.configuration.convert_case = @original_config
  end

  test "convert_case defaults to false" do
    config = ShopifyGraphql::Configuration.new
    assert_equal false, config.convert_case
  end

  test "convert_case can be set to true" do
    ShopifyGraphql.configure do |config|
      config.convert_case = true
    end

    assert_equal true, ShopifyGraphql.configuration.convert_case
  end

  test "case conversion works with snake_case variables" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    query = "query($first_name: String!) { shop { name } }"
    variables = { first_name: "John" }

    fake("queries/shop.json", query, firstName: "John")

    client = ShopifyGraphql::Client.new
    response = client.execute(query, **variables)

    assert_equal "Graphql Gem Test", response.data.shop.name
  end

  test "response keys are converted to snake_case when enabled" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    query = "{ shop { name myshopifyDomain } }"
    fake("queries/shop.json", query)

    client = ShopifyGraphql::Client.new
    response = client.execute(query)

    # Response should have snake_case keys
    assert_equal "Graphql Gem Test", response.data.shop.name
    assert_equal "graphql-gem-test.myshopify.com", response.data.shop.myshopify_domain
  end

  test "original behavior when convert_case is disabled" do
    ShopifyGraphql.configure { |config| config.convert_case = false }

    query = "{ shop { name myshopifyDomain } }"
    fake("queries/shop.json", query)

    client = ShopifyGraphql::Client.new
    response = client.execute(query)

    # Response should maintain original camelCase keys
    assert_equal "Graphql Gem Test", response.data.shop.name
    assert_equal "graphql-gem-test.myshopify.com", response.data.shop.myshopifyDomain
  end

  test "nested structures are converted to snake_case when enabled" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    query = <<~GRAPHQL
      query($id: ID!) {
        product(id: $id) {
          title
          featuredImage {
            originalSrc
            altText
            transformedSrc
          }
          variants(first: 5) {
            edges {
              node {
                displayName
                selectedOptions {
                  name
                  value
                }
                price {
                  amount
                  currencyCode
                }
              }
            }
          }
          metafields(first: 10) {
            edges {
              node {
                namespace
                key
                value
                createdAt
                updatedAt
              }
            }
          }
          seo {
            title
            description
          }
        }
      }
    GRAPHQL

    fake("queries/nested_product.json", query, id: "gid://shopify/Product/12345")

    client = ShopifyGraphql::Client.new
    response = client.execute(query, id: "gid://shopify/Product/12345")
    product = response.data.product

    # Test top-level object
    assert_equal "Complex Product", product.title

    # Test nested object keys converted to snake_case
    assert_equal "https://example.com/image.jpg", product.featured_image.original_src
    assert_equal "Product image", product.featured_image.alt_text
    assert_equal "https://example.com/image_400x400.jpg", product.featured_image.transformed_src

    # Test array of nested objects
    assert_equal 2, product.variants.edges.length
    
    first_variant = product.variants.edges.first.node
    assert_equal "Small / Red", first_variant.display_name
    assert_equal "29.99", first_variant.price.amount
    assert_equal "USD", first_variant.price.currency_code

    # Test deeply nested arrays
    assert_equal 2, first_variant.selected_options.length
    assert_equal "Size", first_variant.selected_options.first.name
    assert_equal "Small", first_variant.selected_options.first.value

    # Test multiple levels of nesting
    second_variant = product.variants.edges.last.node
    assert_equal "Large / Blue", second_variant.display_name
    assert_equal "https://example.com/variant2.jpg", second_variant.image.original_src
    assert_equal "Blue variant", second_variant.image.alt_text

    # Test metafields array conversion
    assert_equal 2, product.metafields.edges.length
    first_metafield = product.metafields.edges.first.node
    assert_equal "care_instructions", first_metafield.key
    assert_equal "Machine wash cold", first_metafield.value
    assert_equal "2024-01-01T00:00:00Z", first_metafield.created_at
    assert_equal "2024-01-02T00:00:00Z", product.metafields.edges.last.node.updated_at

    # Test simple nested object
    assert_equal "SEO Title", product.seo.title
    assert_equal "SEO Description", product.seo.description
  end

  test "nested structures maintain camelCase when convert_case is disabled" do
    ShopifyGraphql.configure { |config| config.convert_case = false }

    query = <<~GRAPHQL
      query($id: ID!) {
        product(id: $id) {
          title
          featuredImage {
            originalSrc
            altText
          }
          variants(first: 5) {
            edges {
              node {
                displayName
                selectedOptions {
                  name
                  value
                }
              }
            }
          }
        }
      }
    GRAPHQL

    fake("queries/nested_product.json", query, id: "gid://shopify/Product/12345")

    client = ShopifyGraphql::Client.new
    response = client.execute(query, id: "gid://shopify/Product/12345")
    product = response.data.product

    # Keys should maintain original camelCase
    assert_equal "https://example.com/image.jpg", product.featuredImage.originalSrc
    assert_equal "Product image", product.featuredImage.altText
    assert_equal "Small / Red", product.variants.edges.first.node.displayName
    assert_equal "Size", product.variants.edges.first.node.selectedOptions.first.name
  end

  test "empty arrays and nil values handled correctly with case conversion" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    # Create a fixture with empty/nil values
    empty_response = {
      data: {
        product: {
          title: "Empty Product",
          featuredImage: nil,
          variants: {
            edges: []
          },
          metafields: {
            edges: []
          }
        }
      }
    }

    query = "{ product { title featuredImage variants { edges } metafields { edges } } }"
    stub_request(:post, "https://test-shop.myshopify.com/admin/api/2024-07/graphql.json")
      .with(body: { query: query, variables: {} })
      .to_return(body: empty_response.to_json)

    client = ShopifyGraphql::Client.new
    response = client.execute(query)
    product = response.data.product

    assert_equal "Empty Product", product.title
    assert_nil product.featured_image
    assert_equal [], product.variants.edges
    assert_equal [], product.metafields.edges
  end

  test "mixed data types preserved with case conversion" do
    ShopifyGraphql.configure { |config| config.convert_case = true }

    mixed_response = {
      data: {
        product: {
          title: "Mixed Product",
          isActive: true,
          priceRange: {
            minVariantPrice: {
              amount: "10.50",
              currencyCode: "USD"
            },
            maxVariantPrice: {
              amount: "25.99",  
              currencyCode: "USD"
            }
          },
          tags: ["summer", "sale", "new-arrival"],
          productType: "Clothing",
          totalInventory: 100
        }
      }
    }

    query = "{ product { title isActive priceRange { minVariantPrice { amount currencyCode } maxVariantPrice { amount currencyCode } } tags productType totalInventory } }"
    stub_request(:post, "https://test-shop.myshopify.com/admin/api/2024-07/graphql.json")
      .with(body: { query: query, variables: {} })
      .to_return(body: mixed_response.to_json)

    client = ShopifyGraphql::Client.new
    response = client.execute(query)
    product = response.data.product

    # Boolean preserved
    assert_equal true, product.is_active
    
    # Nested objects converted
    assert_equal "10.50", product.price_range.min_variant_price.amount
    assert_equal "USD", product.price_range.min_variant_price.currency_code
    assert_equal "25.99", product.price_range.max_variant_price.amount
    
    # Arrays preserved
    assert_equal ["summer", "sale", "new-arrival"], product.tags
    
    # String and numbers preserved  
    assert_equal "Clothing", product.product_type
    assert_equal 100, product.total_inventory
  end
end