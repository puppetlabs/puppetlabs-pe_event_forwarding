# @summary Create the required cron job and scripts for sending Puppet Events
#
# This class will create the cron job that executes the event management script.
# It also creates the event management script in the required directory.
#
# @example
#   include pe_event_forwarding
#
# @param [Optional[String]] pe_username
#   PE username
# @param [Optional[String]] pe_password
#   PE password
# @param [Optional[String]] pe_token
#   PE token
# @param [Optional[String]] pe_console
#   PE console
# @param [Optional[Boolean]] disabled
#   When true, removes cron job
# @param [Optional[String]] cron_minute
#   Sets cron minute (0-59)
# @param [Optional[String]] cron_hour
#   Sets cron hour (0-23)
# @param [Optional[String]] cron_weekday
#   Sets cron day of the week (0-6)
# @param [Optional[String]] cron_month
#   Sets cron month (1-12)
# @param [Optional[String]] cron_monthday
#   Sets cron day of the month (1-31)
# @param [Optional[String]] log_path
#   Should be a directory; base path to desired location for log files
#   `/pe_event_forwarding/pe_event_forwarding.log` will be appended to this param
# @param [Optional[String]] lock_path
#   Should be a directory; base path to desired location for lock file
#   `/pe_event_forwarding/cache/state/events_collection_run.lock` will be appended to this param
# @param [Optional[String]] confdir
#   Path to directory where pe_event_forwarding exists
# @param [Optional[Integer]] api_page_size
#   Sets max number of events retrieved per API call
# @param [Enum['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL']] log_level
#   Determines the severity of logs to be written to log file:
#    - level debug will only log debug-level log messages
#    - level info will log info, warn, and fatal-level log messages
#    - level warn will log warn and fatal-level log messages
#    - level fatal will only log fatal-level log messages
# @param [Enum['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']] log_rotation
#   Determines rotation time for log files
# @param [Optional[Array]] skip_events
#   Array of event types that should be skipped during event collection from the Activity API.
#     Acceptable values are: ['classifier','code-manager','pe-console','rbac']
# @param [Optional[Boolean]] skip_jobs
#   When true, event collection from the Orchestrator API is disabled.
class pe_event_forwarding (
  Optional[String]                                $pe_username            = undef,
  Optional[String]                                $pe_password            = undef,
  Optional[String]                                $pe_token               = undef,
  String                                          $pe_console             = 'localhost',
  Boolean                                         $disabled               = false,
  String                                          $cron_minute            = '*/2',
  String                                          $cron_hour              = '*',
  String                                          $cron_weekday           = '*',
  String                                          $cron_month             = '*',
  String                                          $cron_monthday          = '*',
  Optional[String]                                $log_path               = undef,
  Optional[String]                                $lock_path              = undef,
  Optional[String]                                $confdir                = undef,
  Optional[Integer]                               $api_page_size          = undef,
  Enum['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] $log_level              = 'WARN',
  Enum['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']      $log_rotation           = 'NONE',
  Optional[Array]                                 $skip_events            = undef,
  Optional[Boolean]                               $skip_jobs              = undef,
) {
  # Ensure required credential params are configured
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

  # Remove v1 settings file
  include pe_event_forwarding::v2_cleanup

  # Secure credential data
  $pe_secrets = {
    'pe_token' => $pe_token,
    'pe_username' => $pe_username,
    'pe_password' => $pe_password,
  }
  $secrets = Deferred('pe_event_forwarding::secure', [$pe_secrets])

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

  $logfile_basepath = pe_event_forwarding::base_path($settings::logdir, $log_path)
  $lockdir_basepath = pe_event_forwarding::base_path($settings::statedir, $lock_path)

  if $confdir == undef {
    $full_confdir = "${pe_event_forwarding::base_path($settings::confdir,undef)}/pe_event_forwarding"
  }
  else {
    $full_confdir = "${confdir}/pe_event_forwarding"
  }

  $conf_dirs        = [
    $full_confdir,
    "${full_confdir}/processors.d",
    "${logfile_basepath}/pe_event_forwarding",
    "${lockdir_basepath}/pe_event_forwarding",
    "${lockdir_basepath}/pe_event_forwarding/cache/",
    "${lockdir_basepath}/pe_event_forwarding/cache/state",
  ]

  $cron_command = @("COMMAND"/L)
    ${full_confdir}/collect_api_events.rb ${full_confdir} \
    ${logfile_basepath}/pe_event_forwarding/pe_event_forwarding.log \
    ${lockdir_basepath}/pe_event_forwarding/cache/state
    |-COMMAND

  cron { 'collect_pe_events':
    ensure   => $cron_ensure,
    command  => $cron_command,
    user     => $owner,
    minute   => $cron_minute,
    hour     => $cron_hour,
    weekday  => $cron_weekday,
    month    => $cron_month,
    monthday => $cron_monthday,
    require  => [
      File["${full_confdir}/collection_settings.yaml"],
      File["${full_confdir}/collection_secrets.yaml"],
      File[$conf_dirs]
    ],
  }

  file { $conf_dirs:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { "${full_confdir}/api":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => 'remote',
    source  => 'puppet:///modules/pe_event_forwarding/api',
  }

  file { "${full_confdir}/util":
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => 'remote',
    source  => 'puppet:///modules/pe_event_forwarding/util',
  }

  file { "${full_confdir}/collection_settings.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0640',
    require => File[$full_confdir],
    content => epp('pe_event_forwarding/collection_settings.yaml'),
  }

  file { "${full_confdir}/collection_secrets.yaml":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0600',
    require => File[$full_confdir],
    content => Deferred('inline_epp', [file('pe_event_forwarding/collection_secrets.yaml.epp'), $secrets]),
  }

  file { "${full_confdir}/collect_api_events.rb":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => File[$full_confdir],
    source  => 'puppet:///modules/pe_event_forwarding/collect_api_events.rb',
  }
}
