require 'net/http'
require 'uri'
require 'json'
require 'openssl'
# module Http contains the http utilties for the common gem
module Http
  # post_request takes a hash body and optional headers hash.
  def post_request(hostname, port, uri, body, headers = {}, ssl_verify: true, ca_cert_path: nil)

    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    hostname = hostname.prepend(hostname.start_with?('https://') ? '' : 'https://')
    uri = URI.parse("#{hostname}:#{port}/#{uri}")

    verify_mode = ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

    http = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: verify_mode,
      ca_file: ca_cert_path,
    )

    request = Net::HTTP::Post.new(uri.request_uri, headers)
    request.body = body.to_json

    http.request(request)
  end
  module_function :post_request

  def get_request(hostname, port, uri, headers = {}, ssl_verify: true, ca_cert_path: nil)
    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    hostname = hostname.prepend(hostname.start_with?('https://') ? '' : 'https://')
    uri = URI.parse("https://#{hostname}:#{port}/#{uri}")

    verify_mode = ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

    http = Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: verify_mode,
      ca_cert: ca_cert_path,
    )

    request = Net::HTTP::Get.new(uri.request_uri, headers)

    http.request(request)
  end
  module_function :get_request

  def get_token(pe_console, username, password, ssl_verify: true, ca_cert_path: nil)
    response = post_request(
      pe_console, 4433,
      'rbac-api/v1/auth/token',
      {'login' => username, 'password' => password},
      ssl_verify: ssl_verify,
      ca_cert_path: ca_cert_path
    )
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
