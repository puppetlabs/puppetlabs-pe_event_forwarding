# @summary A subclass to remove old settings file.
#
# @api private
#
# This private subclass is utilized by the main class
# to remove the settings file utilized by v1 of this module.
#
class pe_event_forwarding::v2_cleanup {
  if $pe_event_forwarding::confdir == undef {
    $full_confdir = "${pe_event_forwarding::base_path($settings::confdir,undef)}/pe_event_forwarding"
  }
  else {
    $full_confdir = "${pe_event_forwarding::confdir}/pe_event_forwarding"
  }

  file { "${full_confdir}/events_collection.yaml":
    ensure  => absent,
  }
}
