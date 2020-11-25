require 'net/http'
require 'uri'
require 'json'
require 'openssl'

# class CommonEventsHttp contains the http utilties for the common gem
class CommonEventsHttp
  attr_accessor :hostname, :port, :username, :password, :ssl_verify, :ca_cert_path

  # Query specific data like headers, bodies, and uri's are passed into each method.
  def initialize(hostname, port: nil, username: nil, password: nil, ssl_verify: true, ca_cert_path: nil)
    @hostname     = hostname.start_with?('https://') ? hostname : 'https://' + hostname
    @port         = port
    @username     = username
    @password     = password
    @ssl_verify   = ssl_verify
    @ca_cert_path = ca_cert_path
  end

  # post_request takes a uri(string), body(hash), headers(optional(hash)), and a timeout(optional(int)).
  # Basic auth will be used if provided.
  def post_request(uri, body, headers = {}, timeout = 60)
    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    url = URI.parse("#{hostname_with_port}/#{uri}")
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

    request.basic_auth(username, password) if username && password

    http.request(request)
  end

  # post_request takes a uri(string), headers(optional(hash)), and a timeout(optional(int)).
  # Basic auth will be used if provided.
  def get_request(uri, headers = {}, timeout = 60)
    headers['Content-Type'] = 'application/json' unless headers.key? 'Content-Type'
    url = URI.parse("#{hostname_with_port}/#{uri}")
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

    request.basic_auth(username, password) if username && password

    http.request(request)
  end

  def hostname_with_port
    port ? "#{hostname}:#{port}" : hostname
  end

  def self.make_params(uri, limit, offset)
    return_uri = "#{uri}?limit=#{limit}" unless limit.zero?
    return_uri = "#{uri}&offset=#{offset}" unless offset.zero? && limit
    return_uri = "#{uri}?offset=#{offset}" unless offset.zero? && limit.zero?
    return_uri = uri if return_uri.nil?
    return_uri
  end

  def self.response_to_hash(response)
    raise "Response has no body #{response}" unless response.respond_to? 'body'
    JSON.parse(response.body)
  end
end
