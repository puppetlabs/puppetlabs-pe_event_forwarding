#!/opt/puppetlabs/puppet/bin/ruby

require 'net/https'
require 'uri'
require 'json'

def generate_classifier_event(count, token)
  (1..count).each do |i|
    id         = "00000000-0000-4000-8000-00000000000#{i}"
    uri        = URI.parse("https://localhost:4433/classifier-api/v1/groups/#{id}")
    node_group = {
      'parent'  => '00000000-0000-4000-8000-000000000000',
      'name'    => "Node Group #{i}",
      'classes' => {},
    }

    Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_NONE,
      ) do |http|
      request = Net::HTTP::Put.new uri
      request.add_field('X-Authentication', token)
      request.add_field('Content-Type', 'application/json')
      request.body = node_group.to_json

      response = http.request request
      if response.code != '201'
        puts "Error: #{response.body}"
        exit 1
      end
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

generate_classifier_event(count, token)
