# @summary Install PE Server
#
# Install PE Server
#
# @example
#   pe_event_forwarding::acceptance::pe_server
#
# @param version
#   PE version
# @param pe_settings
#   Hash with key `password` and value of PE console password for admin user
plan pe_event_forwarding::acceptance::pe_server(
  Optional[String] $version = '2023.8.0',
  Optional[Hash] $pe_settings = {password => 'puppetlabsPi3!', configure_tuning => false}) {
  # machines are not yet ready at time of installing the puppetserver, so we wait 30s
  $localhost = get_targets('localhost')
  run_command('sleep 30s', $localhost)

  #identify pe server node
  $puppet_server = get_targets('*').filter |$n| { $n.vars['role'] == 'server' }

  # extract pe version from matrix_from_metadata_v3 output
  $ent_version = regsubst($version, '-puppet_enterprise', '')

  # install pe server
  run_plan(
    'deploy_pe::provision_master',
    $puppet_server,
    'version' => $ent_version,
    'pe_settings' => $pe_settings
  )

  $cmd = @("CMD")
    echo 'puppetlabsPi3!' | puppet access login --lifetime 1y --username admin
    puppet infrastructure tune | sed "s,\\x1B\\[[0-9;]*[a-zA-Z],,g" > /etc/puppetlabs/code/environments/production/data/common.yaml
    puppet agent -t
    | CMD

  run_command($cmd, $puppet_server, '_catch_errors' => true)
}
