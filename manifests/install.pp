# @summary Create the required cron job and scripts for sending Puppet Events
#
# This class will create the cron job that executes the event management script.
# It also creates the event management script in the required directory.
#
class common_events::install {

  if (
    ($common_events::pe_token == undef)
    and
    ($common_events::pe_username == undef or $common_events::pe_password == undef)
  ) {
    $authorization_failure_message = @(MESSAGE/L)
    Please set both 'pe_username' and 'pe_password' \
    if you are not using a pre generated PE authorization \
    token in the 'pe_token' parameter
    |-MESSAGE
    fail($authorization_failure_message)
  }

  # Account for the differences in Puppet Enterprise and open source
  if $facts[pe_server_version] != undef {
    $owner          = 'pe-puppet'
    $group          = 'pe-puppet'
    $confdir        = "${settings::confdir}/common_events"
    $modulepath     = $settings::modulepath
  }
  else {
    notify { 'Non-PE':
      message => 'Error: This module is intended for use with Puppet Enterprise only.',
    }
  }

  cron { 'collect_common_events':
    ensure  => 'present',
    command => "${confdir}/collect_api_events.rb ${confdir} ${modulepath} ${confdir}",
    user    => 'root',
    minute  => '*/2',
    require => [
      File["${confdir}/events_collection.yaml"]
    ],
  }

  file { $confdir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { "${confdir}/api":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => 'remote',
    source  => 'puppet:///modules/common_events/api',
  }

  file { "${confdir}/util":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => 'remote',
    source  => 'puppet:///modules/common_events/util',
  }

  file { "${confdir}/events_collection.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    require => File[$confdir],
    content => epp('common_events/events_collection.yaml'),
  }

  file { "${confdir}/collect_api_events.rb":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File[$confdir],
    source  => 'puppet:///modules/common_events/collect_api_events.rb',
  }
}
