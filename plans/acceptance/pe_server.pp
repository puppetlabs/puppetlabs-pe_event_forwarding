# @summary Install PE Server
#
# Install PE Server
#
# @example
#   common_events::acceptance::pe_server
plan common_events::acceptance::pe_server(
  Optional[String] $version = '2019.8.5',
  Optional[Hash] $pe_settings = {password => 'puppetlabs'}
) {
  #identify pe server node
  $puppet_server =  get_targets('*').filter |$n| { $n.vars['role'] == 'server' }

  # install pe server
  run_plan(
    'deploy_pe::provision_master',
    $puppet_server,
    'version' => $version,
    'pe_settings' => $pe_settings
  )

  $cmd = @("CMD")
          puppet infra console_password --password=pie
          echo 'pie' | puppet access login --lifetime 1y --username admin
          | CMD

  run_command($cmd, $puppet_server, '_catch_errors' => true)
}
