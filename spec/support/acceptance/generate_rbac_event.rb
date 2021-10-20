#!/usr/bin/ruby

require 'net/https'
require 'uri'
require 'json'

def generate_rbac_event(count = 1)
  uri       = URI.parse('https://localhost:4433/rbac-api/v1/users')
  token     = `puppet access show`.chomp
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

  begin
    count = ARGV[0].to_i
  rescue => exception
    puts "Could not convert to integer: #{exception}"
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

generate_rbac_event
