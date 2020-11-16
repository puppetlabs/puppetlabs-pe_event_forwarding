require 'net/http'
require 'uri'
require 'json'
require 'openssl'
# module Http contains the http utilties for the common gem
module Http
  # post_request takes a hash body and optional headers hash.
  # Specify either user/password or token/destination.
  # Acceptable destination parameters are 'pe', 'sn', and 'splunk'.
  # Token/destination will be used if both forms of auth are provided.
  def post_request(hostname,
                   port,
                   uri,
                   body,
                   headers = {},
                   ssl_verify: true,
                   ca_cert_path: nil,
                   user: nil,
                   password: nil,
                   destination: nil,
                   token: nil,
                   timeout: 60)

    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    nodename = hostname.start_with?('https://') ? hostname : "https://#{hostname}"
    url = URI.parse("#{nodename}:#{port}/#{uri}")
    verify_mode = ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

    http = Net::HTTP.start(
      url.host,
      url.port,
      use_ssl: url.scheme == 'https',
      verify_mode: verify_mode,
      ca_file: ca_cert_path,
      read_timeout:    timeout,
      connect_timeout: timeout,
      ssl_timeout:     timeout,
      write_timeout:   timeout,
    )

    request = Net::HTTP::Post.new(url.request_uri, headers)
    request.body = body.to_json

    # The PE token endpoint expects the password in the body
    if body['password'].nil?
      # prioritize OAuth
      if token
        oauth_header = make_oauth_header(destination, token)
        request[oauth_header.keys.first] = oauth_header.values.first
      else
        # We use the basic_auth method to take advantage of the built in Base64 encoder.
        request.basic_auth(user, password)
      end
    end

    request.body = body.to_json
    http.request(request)
  end
  module_function :post_request

  # Specify either user/password or token/destination.
  # Acceptable destination parameters are 'pe', 'sn', and 'splunk'.
  # Token/destination will be used if both forms of auth are provided.
  def get_request(hostname,
                  port,
                  uri,
                  headers: {},
                  ssl_verify: true,
                  ca_cert_path: nil,
                  user: nil,
                  password: nil,
                  destination: nil,
                  token: nil,
                  timeout: 60)

    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    nodename = hostname.start_with?('https://') ? hostname : "https://#{hostname}"
    url = URI.parse("#{nodename}:#{port}/#{uri}")
    verify_mode = ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

    http = Net::HTTP.start(
      url.host,
      url.port,
      use_ssl: url.scheme == 'https',
      verify_mode: verify_mode,
      ca_cert: ca_cert_path,
      read_timeout:    timeout,
      connect_timeout: timeout,
      ssl_timeout:     timeout,
      write_timeout:   timeout,
    )

    request = Net::HTTP::Get.new(url.request_uri, headers)

    # prioritize OAuth
    if token
      oauth_header = make_oauth_header(destination, token)
      request[oauth_header.keys.first] = oauth_header.values.first
    elsif ssl_verify
      # We use the basic_auth method to take advantage of the built in Base64 encoder.
      request.basic_auth(user, password)
    end

    http.request(request)
  end
  module_function :get_request

  def get_pe_token(pe_console, username, password, ssl_verify: true, ca_cert_path: nil)
    response = post_request(
      pe_console,
      4433,
      'rbac-api/v1/auth/token',
      { 'login' => username, 'password' => password },
      ssl_verify: ssl_verify,
      ca_cert_path: ca_cert_path,
    )
    token_hash = JSON.parse(response.body)
    token_hash['token']
  end
  module_function :get_pe_token

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

  # This method prepares OAuth headers for a specified destination.
  # Acceptable destination parameters are 'pe', 'sn', and 'splunk'.
  def make_oauth_header(destination, token)
    raise ArgumentError, "expects destination parameter to be 'pe', 'sn', or 'splunk'" unless ['pe', 'sn', 'splunk'].include?(destination.downcase)
    case destination.downcase
    when 'pe'
      { 'X-Authentication' => token.to_s }
    when 'sn'
      { 'Authentication' => "Bearer #{token}" }
    when 'splunk'
      { 'Authorization' => "Splunk #{token}" }
    end
  end
  module_function :make_oauth_header
end
