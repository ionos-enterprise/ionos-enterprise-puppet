require 'profitbricks'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'webmock/rspec'

WebMock.disable_net_connect!

def stub_wait_for(rest_url, headers)
  stub_request(:get, "#{rest_url}/requests/123?depth=1").
    with(headers: headers).
    to_return(body: '{"id":"123","metadata":{"status":"DONE"}}')

  stub_request(:get, "#{rest_url}/requests/123/status?depth=1").
    with(headers: headers).
    to_return(body: '{"id":"123","metadata":{"status":"DONE"}}')
end

# TODO: Add mock data and tests for providers
