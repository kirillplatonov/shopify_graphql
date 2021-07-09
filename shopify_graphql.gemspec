require_relative "lib/shopify_graphql/version"

Gem::Specification.new do |spec|
  spec.name        = "shopify_graphql"
  spec.version     = ShopifyGraphql::VERSION
  spec.authors     = ["Kirill Platonov"]
  spec.email       = ["me@kirillplatonov.com"]
  spec.summary     = "Ruby wrapper for Shopify GraphQL API"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0"
  spec.add_dependency "shopify_app", "> 17.0"
  spec.add_dependency "gqli"
end
