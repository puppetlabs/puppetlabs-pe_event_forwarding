#!/usr/bin/ruby

require 'net/https'
require 'uri'
require 'json'

def generate_rbac_event(count, token)
  uri       = URI.parse('https://localhost:4433/rbac-api/v1/users')
  rbac_user = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    ) do |http|
    request = Net::HTTP::Get.new uri
    request.add_field('X-Authentication', token)

    response      = http.request request
    data_response = JSON.parse(response.body)
    data_response.find { |user| user['login'] == 'admin' }
  end

  (1..count).each do |i|
    id                 = rbac_user['id']
    rbac_user['email'] = "blah-#{i}@bar.com"
    modified_user      = rbac_user.to_json
    uri                = URI.parse("https://localhost:4433/rbac-api/v1/users/#{id}")

    Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_NONE,
      ) do |http|
      request = Net::HTTP::Put.new uri
      request.add_field('X-Authentication', token)
      request.add_field('Content-Type', 'application/json')
      request.body = modified_user

      http.request request
    end
  end
end

begin
  count = ARGV[0].nil? ? 1 : ARGV[0].to_i
rescue => exception
  puts "Could not convert to integer: #{exception}"
end

begin
  token = `puppet access show`.chomp
rescue => exception
  throw "Could not find access token: #{exception}"
end

generate_rbac_event(count, token)
