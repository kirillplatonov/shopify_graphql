require_relative "lib/shopify_graphql/version"

Gem::Specification.new do |spec|
  spec.name        = "shopify_graphql"
  spec.version     = ShopifyGraphql::VERSION
  spec.authors     = ["Kirill Platonov"]
  spec.email       = ["mail@kirillplatonov.com"]

  spec.homepage    = "https://github.com/kirillplatonov/shopify_graphql"
  spec.summary     = "Less painful way to work with Shopify Graphql API in Ruby."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
    "public gem pushes."
  end

  spec.files = Dir["{app,config,lib}/**/*", "LICENSE.txt", "README.md"]

  spec.required_ruby_version = ">= 2.7.0"
  spec.add_dependency "rails", [">= 5.2.0", "< 7.0.0"]
  spec.add_dependency "shopify_app", "> 17.0"
  spec.add_dependency "faraday", ">= 1.0"
  spec.add_dependency "faraday_middleware"
end
