require 'net/http'
require 'uri'
require 'json'
require 'openssl'

PE_CONSOLE=ENV['PT_PE_CONSOLE']
USERNAME=ENV['PT_PE_USERNAME'] || 'admin'
PASSWORD=ENV['PT_PE_PASSWORD'] || 'pie'

def post_request(hostname, port, uri, body)
   header = {'Content-Type': 'text/json'}
   uri = URI.parse("https://#{hostname}:#{port}/#{uri}")

   http = Net::HTTP.start(uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE)

   header = { 'Content-Type' => 'application/json' }
   request = Net::HTTP::Post.new(uri.request_uri, header)
   request.body = body.to_json

   response = http.request(request)
end

def get_request(hostname, port, uri, headers={})
   headers['Content-Type'] = 'application/json' unless headers.has_key? 'Content-Type'
   uri = URI.parse("https://#{hostname}:#{port}/#{uri}")

   http = Net::HTTP.start(uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE)


   request = Net::HTTP::Get.new(uri.request_uri, headers)

   response = http.request(request)
end


def get_token
   response = post_request(PE_CONSOLE, 4433, 'rbac-api/v1/auth/token', {"login": USERNAME, "password": PASSWORD})
   token_hash = JSON.parse(response.body)
   token_hash['token']
end

def get_all_orchestrator_jobs(token)
   auth_header = {'X-Authentication': "#{token}"}
   response = get_request(PE_CONSOLE, 8143, 'orchestrator/v1/jobs', auth_header)
end


token = get_token()

response = get_all_orchestrator_jobs(token)

puts response.body






