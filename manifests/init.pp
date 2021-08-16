# @summary Create the required cron job and scripts for sending Puppet Events
#
# This class will create the cron job that executes the event management script.
# It also creates the event management script in the required directory.
#
# @example
#   include common_events
class common_events (
  Optional[String]                                $pe_username   = undef,
  Optional[Sensitive[String]]                     $pe_password   = undef,
  Optional[String]                                $pe_token      = undef,
  Optional[Boolean]                               $disabled      = false,
  Optional[String]                                $cron_minute   = '*/2',
  Optional[String]                                $cron_hour     = '*',
  Optional[String]                                $cron_weekday  = '*',
  Optional[String]                                $cron_month    = '*',
  Optional[String]                                $cron_monthday = '*',
  Optional[String]                                $log_path      = undef,
  Enum['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'] $log_level     = 'WARN',
){
  include common_events::install
}
