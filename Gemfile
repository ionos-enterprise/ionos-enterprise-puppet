source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'profitbricks-sdk-ruby', '1.0.5'

group :test do
  gem 'rake'
  gem 'puppet', *location_for(ENV['PUPPET_LOCATION'] || '~> 3.7.0')
  gem 'puppetlabs_spec_helper'
  gem 'webmock'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
end

group :development do
  gem 'travis'
  gem 'travis-lint'
  gem 'puppet-blacksmith'
  gem 'guard-rake'
  gem 'rubocop', require: false
end
