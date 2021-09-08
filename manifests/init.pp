# @summary Create the required cron job and scripts for sending Puppet Events
#
# This class will create the cron job that executes the event management script.
# It also creates the event management script in the required directory.
#
# @example
#   include common_events
class common_events (
  Optional[String]                                $pe_username      = undef,
  Optional[Sensitive[String]]                     $pe_password      = undef,
  Optional[String]                                $pe_token         = undef,
  Optional[String]                                $pe_console       = 'localhost',
  Optional[Boolean]                               $disabled         = false,
  Optional[String]                                $cron_minute      = '*/2',
  Optional[String]                                $cron_hour        = '*',
  Optional[String]                                $cron_weekday     = '*',
  Optional[String]                                $cron_month       = '*',
  Optional[String]                                $cron_monthday    = '*',
  Optional[String]                                $log_path         = undef,
  Optional[String]                                $lock_path        = undef,
  Optional[String]                                $confdir          = "${common_events::base_path($settings::confdir,undef)}/common_events",
  Enum['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] $log_level        = 'WARN',
  Enum['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']      $log_rotation     = 'NONE',
){

  if (
    ($pe_token == undef)
    and
    ($pe_username == undef or $pe_password == undef)
  ) {
    $authorization_failure_message = @(MESSAGE/L)
    Please set both 'pe_username' and 'pe_password' \
    if you are not using a pre generated PE authorization \
    token in the 'pe_token' parameter
    |-MESSAGE
    fail($authorization_failure_message)
  }

  # Account for the differences in running on Primary Server or Agent Node
  if $facts[pe_server_version] != undef {
    $owner              = 'pe-puppet'
    $group              = 'pe-puppet'
  }
  else {
    $owner              = 'root'
    $group              = 'root'
  }

  unless $disabled {
    $cron_ensure = present
  } else {
    $cron_ensure = absent
  }

  $logfile_basepath = common_events::base_path($settings::logdir, $log_path)
  $lockdir_basepath = common_events::base_path($settings::statedir, $lock_path)
  $conf_dirs        = [$confdir, "${logfile_basepath}/common_events", "${lockdir_basepath}/common_events", "${lockdir_basepath}/common_events/cache/", "${lockdir_basepath}/common_events/cache/state"]

  cron { 'collect_common_events':
    ensure   => $cron_ensure,
    command  => "${confdir}/collect_api_events.rb ${confdir} ${logfile_basepath}/common_events/common_events.log ${lockdir_basepath}/common_events/cache/state",
    user     => 'root',
    minute   => $cron_minute,
    hour     => $cron_hour,
    weekday  => $cron_weekday,
    month    => $cron_month,
    monthday => $cron_monthday,
    require  => [
      File["${confdir}/events_collection.yaml"],
      File[$conf_dirs]
    ],
  }

  file { $conf_dirs:
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
