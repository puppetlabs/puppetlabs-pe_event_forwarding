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
    $owner              = 'pe-puppet'
    $group              = 'pe-puppet'
    $confdir            = "${settings::confdir}/common_events"
    $logfile_basepath   = common_events::base_path($settings::logdir, $common_events::log_path)
    $lockdir_basepath   = common_events::base_path($settings::statedir, undef)
    $lock_dirs = ["${lockdir_basepath}/common_events", "${lockdir_basepath}/common_events/cache/", "${lockdir_basepath}/common_events/cache/state"]
  }
  else {
    notify { 'Non-PE':
      message => 'Error: This module is intended for use with Puppet Enterprise only.',
    }
  }

  unless $common_events::disabled {
    $cron_ensure = present
  } else {
    $cron_ensure = absent
  }

  cron { 'collect_common_events':
    ensure   => $cron_ensure,
    command  => "${confdir}/collect_api_events.rb ${confdir} ${logfile_basepath}/common_events/common_events.log ${lockdir_basepath}/common_events/cache/state",
    user     => 'root',
    minute   => $common_events::cron_minute,
    hour     => $common_events::cron_hour,
    weekday  => $common_events::cron_weekday,
    month    => $common_events::cron_month,
    monthday => $common_events::cron_monthday,
    require  => [
      File["${confdir}/events_collection.yaml"],
      File[$lock_dirs]
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

  file {"${logfile_basepath}/common_events":
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file {$lock_dirs:
    ensure => directory,
    owner  => $owner,
    group  => $group,
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
