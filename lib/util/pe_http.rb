require_relative 'common_events_http'

# Include methods to secure a token and construct auth headers
class PeHttp < CommonEventsHttp
  attr_accessor :hostname, :port, :username, :pe_username, :pe_password, :password, :token, :ssl_verify, :ca_cert_path

  def initialize(hostname, port: nil, username: nil, password: nil, token: nil, ssl_verify: true, ca_cert_path: nil)
    validate_pe_http_class(username, password, token)
    super(hostname,
          port: port,
          username: nil,
          password: nil,
          ssl_verify: ssl_verify,
          ca_cert_path: ca_cert_path)
    @hostname = hostname.start_with?('https://') ? hostname : 'https://' + hostname
    # These instance variables are used to re-generate a token.
    # This allows us to nil out the more generic username and password from the superclass so that basic auth will not be used.
    @pe_username = username
    @pe_password = password
    # Tokens are not stored in the parent class since OAuth is passed in as a header.
    @token = token ? token : get_pe_token
  end

  def validate_pe_http_class(username, password, token)
    invalid = token.nil? && (username.nil? || password.nil?)
    raise ArgumentError, 'Must specify username and password or token.' if invalid
  end

  # Wrapper method for get_request that includes a token auth header for PE.
  def pe_get_request(uri, headers = {}, timeout = 60)
    get_request(uri, headers.merge(pe_auth_header), timeout)
  end

  # Wrapper method for post_request that includes a token auth header for PE.
  def pe_post_request(uri, body, headers = {}, timeout = 60)
    post_request(uri, body, headers.merge(pe_auth_header), timeout)
  end

  def get_pe_token
    # Preserve the object's port while we substitute 4433 for getting a token.
    temp_port = port
    self.port = 4433
    body = { 'login' => pe_username, 'password' => pe_password }
    response = post_request('rbac-api/v1/auth/token', body)
    token_hash = JSON.parse(response.body)
    # restore the original port
    self.port = temp_port
    self.token = token_hash['token']
  end

  def pe_auth_header
    raise 'No token available. Please generate one with the get_pe_token method.' unless token
    { 'X-Authentication' => token.to_s }
  end
end
