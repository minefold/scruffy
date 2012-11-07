source :rubygems

gem 'rake'

gem 'eventmachine', '1.0.0.beta.3'
gem 'eventmachine-tail'
gem 'em-http-request'

gem 'fog', '~> 1.2.0' #code: '~/code/whatupdave/fog'

gem 'mongo'
gem 'bson_ext'

gem "hiredis", "~> 0.4.0"
gem "redis", ">= 2.2.0", :require => ["redis/connection/hiredis", "redis"]
gem 'em-hiredis', '~> 0.1.1'
gem 'resque'
gem "resque-loner", git: 'https://github.com/whatupdave/resque-loner'
gem 'statsd-instrument', git:'https://github.com/Shopify/statsd-instrument.git'

gem 'hirb'
gem 'exceptional'

group :development do
  gem 'pry'
end

group :test do
  gem "turn", require: false 
end
