require 'shopify_api'
require 'active_support'

require 'shopify_graphql/client'
require 'shopify_graphql/configuration'
if defined?(Rails)
  require 'shopify_graphql/engine'
end
require 'shopify_graphql/exceptions'
require 'shopify_graphql/mutation'
require 'shopify_graphql/query'
require 'shopify_graphql/resource'
require 'shopify_graphql/response'
require 'shopify_graphql/version'

# controller concerns
require 'shopify_graphql/controller_concerns/payload_verification'
require 'shopify_graphql/controller_concerns/webhook_verification'

# jobs
if defined?(Rails)
  require 'shopify_graphql/jobs/create_webhooks_job'
  require 'shopify_graphql/jobs/destroy_webhooks_job'
  require 'shopify_graphql/jobs/update_webhooks_job'
end

# managers
require 'shopify_graphql/managers/webhooks_manager'

# resources
require 'shopify_graphql/resources/shop'
require 'shopify_graphql/resources/webhook'
