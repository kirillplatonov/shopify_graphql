require_relative "lib/shopify_graphql/version"

Gem::Specification.new do |spec|
  spec.name        = "shopify_graphql"
  spec.version     = ShopifyGraphQL::VERSION
  spec.authors     = ["Kirill Platonov"]
  spec.email       = ["me@kirillplatonov.com"]
  spec.summary     = "Ruby wrapper for Shopify GraphQL API"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.2"
  spec.add_dependency "shopify_app", "> 17.0"
  spec.add_dependency 'faraday', '>= 1.0'
  spec.add_dependency 'faraday_middleware'
end
