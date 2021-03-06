# HEY, LOOK HERE!!!
# NEVER, EVER, EVER CHANGE THIS FILE.

unless RUBY_VERSION.match(/1.8/)
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

# CREATE A environment.local.rb FILE INSTEAD

if File.exists?(__FILE__.sub(/\.rb$/, ".local.rb"))
  require __FILE__.sub(/\.rb$/, ".local.rb")
end

# Bootstrap the Rails environment, frameworks, and default configuration

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', "vendor", "soap4r"))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', "vendor", "plugins", "soap4r-middleware", "lib"))

require File.join(File.dirname(__FILE__), 'boot')

require 'soap4r-middleware'

require File.join(File.dirname(__FILE__), '..', 'lib', 'soap.rb')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  config.middleware.use MyAPIMiddleware

  # Specify gems that this application depends on. 
  # They can then be installed with "rake gems:install" on new installations.
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  # config.time_zone = 'blah blah blah'

  # no, we don't want to do this, since it appears we are currently
  # storing it in our timezone in the db, and that will make times
  # strange. I hate rails.
  #   -- Ryan52

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_test_session',
    :secret      => 'd0135c9236d736499295b3e509b14ef3628bd7399b17b8b7d7e015fac0558540d6a9697719310fea4f48379df920dd829d19b356ecc2c01217c3a4243705aea0'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
end
