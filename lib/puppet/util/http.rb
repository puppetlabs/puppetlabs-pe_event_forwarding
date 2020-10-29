require 'net/http'
require 'uri'
require 'json'
require 'openssl'
# module Http contains the http utilties for the common gem
module Http
  # post_request takes a hash body and optional headers hash.
  def post_request(hostname, port, uri, body, headers = {})
    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    uri = URI.parse("https://#{hostname}:#{port}/#{uri}")

    http = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    )

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = body.to_json

    http.request(request)
  end
  module_function :post_request

  def get_request(hostname, port, uri, headers = {})
    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    uri = URI.parse("https://#{hostname}:#{port}/#{uri}")

    http = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    )

    request = Net::HTTP::Get.new(uri.request_uri, headers)

    http.request(request)
  end
  module_function :get_request

  def get_token(pe_console, username, password)
    response = post_request(pe_console, 4433, 'rbac-api/v1/auth/token', 'login' => username, 'password' => password)
    token_hash = JSON.parse(response.body)
    token_hash['token']
  end
  module_function :get_token

  def make_params(uri, limit, offset)
    uri = "#{uri}?limit=#{limit}" unless limit.zero?
    uri = "#{uri}&offset=#{offset}" unless offset.zero? && limit
    uri = "#{uri}?offset=#{offset}" unless offset.zero? && limit.zero?
    uri
  end
  module_function :make_params

  def response_to_hash(response)
    raise "Response has no body #{response}" unless response.respond_to? 'body'
    JSON.parse(response.body)
  end
  module_function :response_to_hash
end
