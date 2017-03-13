source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'profitbricks-sdk-ruby', '3.0.2'

# Find a location or specific version for a gem. place_or_version can be a
# version, which is most often used. It can also be git, which is specified as
# `git://somewhere.git#branch`. You can also use a file source location, which
# is specified as `file://some/location/on/disk`.
def location_for(place_or_version, fake_version = nil)
  if place_or_version =~ /^(git[:@][^#]*)#(.*)/
    [fake_version, { :git => $1, :branch => $2, :require => false }].compact
  elsif place_or_version =~ /^file:\/\/(.*)/
    ['>= 0', { :path => File.expand_path($1), :require => false }]
  else
    [place_or_version, { :require => false }]
  end
end

group :test do
  gem 'rake'
  gem 'puppet', *location_for(ENV['PUPPET_LOCATION'] || '~> 3.7.0')
  gem 'puppetlabs_spec_helper'
  gem 'webmock'
  gem 'vcr'
  gem 'rspec-puppet', :git => 'https://github.com/rodjek/rspec-puppet.git'
end

group :development do
  gem 'travis'
  gem 'travis-lint'
  gem 'puppet-blacksmith'
  gem 'rubocop', require: false
end
