require 'serverspec'
require 'puppet_litmus'
require 'support/acceptance/helpers.rb'

include PuppetLitmus
PuppetLitmus.configure!

CONFDIR = '/etc/puppetlabs'.freeze
LOGDIR  = '/var/log/puppetlabs/pe_event_forwarding'.freeze
LOCKFILEDIR = '/opt/puppetlabs/pe_event_forwarding/cache/state'.freeze

RSpec.configure do |config|
  include TargetHelpers

  config.before(:suite) do
    # Stop the puppet service on the puppetserver to avoid edge-case conflicting
    # Puppet runs (one triggered by service vs one we trigger)
    puppetserver.run_shell('puppet resource service puppet ensure=stopped')
    acceptance_setup
  end
end

def acceptance_setup
  set_sitepp_content(declare('class', 'pe_event_forwarding', { 'pe_token' => auth_token, 'disabled' => true }))
  trigger_puppet_run(puppetserver)
end

def console_host_fqdn
  @console_host_fqdn ||= puppetserver.run_shell('hostname -A').stdout.strip
end

def auth_token
  @auth_token ||= puppetserver.run_shell('puppet access show').stdout.chomp
end

# TODO: This will cause some problems if we run the tests
# in parallel. For example, what happens if two targets
# try to modify site.pp at the same time?
def set_sitepp_content(manifest)
  content = <<-HERE
  node default {
    #{manifest}
  }
  HERE

  puppetserver.write_file(content, '/etc/puppetlabs/code/environments/production/manifests/site.pp')
  puppetserver.run_shell('chown pe-puppet:pe-puppet /etc/puppetlabs/code/environments/production/manifests/site.pp')
end

def trigger_puppet_run(target, acceptable_exit_codes: [0, 2])
  result = target.run_shell('puppet agent -t --detailed-exitcodes', expect_failures: true)
  unless acceptable_exit_codes.include?(result[:exit_code])
    raise "Puppet run failed\nstdout: #{result[:stdout]}\nstderr: #{result[:stderr]}"
  end
  result
end

def declare(type, title, params = {})
  params = params.map do |name, value|
    value = "'#{value}'" if value.is_a?(String)
    "  #{name} => #{value},"
  end

  <<-HERE
  #{type} { '#{title}':
  #{params.join("\n")}
  }
  HERE
end

def to_manifest(*declarations)
  declarations.join("\n")
end

def setup_manifest(pe_token, cron_disabled: true)
  <<-MANIFEST
  class { 'pe_event_forwarding':
    pe_token => '#{pe_token}',
    disabled => '#{cron_disabled}',
  }
  MANIFEST
end

def cron_schedule
  {
    cron_minute:   '10',
    cron_hour:     '9',
    cron_weekday:  '3',
    cron_month:    '7',
    cron_monthday: '6',
  }
end
