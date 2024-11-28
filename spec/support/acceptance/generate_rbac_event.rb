#!/opt/puppetlabs/puppet/bin/ruby

require 'net/https'
require 'uri'
require 'json'
require 'optparse'

def create_rbac_user(login, token)
  uri   = URI.parse('https://localhost:4433/rbac-api/v1/users')
  user  = {
    'login' => login,
    'email' => '',
    'display_name' => "Integrations #{login}",
    'role_ids' => [],
  }

  Net::HTTP.start(
      uri.host,
      uri.port,
      use_ssl: true,
      verify_mode: OpenSSL::SSL::VERIFY_NONE,
    ) do |http|
    request = Net::HTTP::Post.new uri
    request.add_field('X-Authentication', token)
    request.add_field('Content-Type', 'application/json')
    request.body = user.to_json

    response = http.request request
    if response.code != '303'
      puts "Error: #{response.body}"
      exit 1
    end
  end
end

def update_user_email(login, email, token)
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
    data_response.find { |user| user['login'] == login }
  end

  if rbac_user.nil?
    puts "Error: Unable to find user with login #{login}!"
    exit 1
  end

  id                 = rbac_user['id']
  rbac_user['email'] = email
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

    response = http.request request
    if response.code != '200'
      puts "Error: #{response.body}"
      exit 1
    end
  end
end

options = {
  login: 'pie_user',
  email: 'integrations@example.com'
}

OptionParser.new { |opts|
  opts.banner = 'Usage: generate_rbac_event.rb [--create [--login user]] [--update [--login user] [--email email]]'
  opts.on('-c', '--create', TrueClass, 'Create PE RBAC user') { |o| options[:create] = o }
  opts.on('-e', '--email [email]', String, 'RBAC user email address') { |o| options[:email] = o }
  opts.on('-l', '--login [user]', String, 'The RBAC account to create/update') { |o| options[:login] = o }
  opts.on('-u', '--update', TrueClass, 'Update RBAC user account') { |o| options[:update] = o }
}.parse!

begin
  token = `puppet access show`.chomp
rescue => exception
  throw "Could not find access token: #{exception}"
end

if options[:create]
  create_rbac_user(options[:login], token)
elsif options[:update]
  update_user_email(options[:login], options[:email], token)
end
