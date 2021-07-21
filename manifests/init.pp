# @summary Create the required cron job and scripts for sending Puppet Events
#
# This class will create the cron job that executes the event management script.
# It also creates the event management script in the required directory.
#
# @example
#   include common_events
class common_events (
  Optional[String]            $pe_username = undef,
  Optional[Sensitive[String]] $pe_password = undef,
  Optional[String]            $pe_token    = undef,
){
  include common_events::install
}
