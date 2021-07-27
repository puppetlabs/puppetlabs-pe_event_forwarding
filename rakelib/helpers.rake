require_relative '../spec/support/acceptance/helpers'

include TargetHelpers

def servicenow_params(args)
  args.names.map do |name|
    args[name] || ENV[name.to_s.upcase]
  end
end

# Executes a command locally.
#
# @param command [String] command to execute.
# @return [Object] the standard out stream.
def run_local_command(command)
  stdout, stderr, status = Open3.capture3(command)
  error_message = "Attempted to run\ncommand:'#{command}'\nstdout:#{stdout}\nstderr:#{stderr}"
  raise error_message unless status.to_i.zero?

  stdout
end

def task_prefix(hostname)
  "bundle exec bolt task run --modulepath spec/fixtures/modules --target #{hostname}"
end

namespace :acceptance do
  desc 'Upload Test Processors'
  task :upload_processors do
    ['proc1.sh', 'proc2.rb'].each do |processor|
      proc_path = "spec/support/acceptance/#{processor}"
      folder = '/etc/puppetlabs/puppet/common_events/processors.d'
      server.run_shell("mkdir -p #{folder}")
      server.bolt_upload_file(proc_path, folder)
      server.run_shell("chmod +x #{folder}/#{processor}")
    end
  end

  desc 'Provisions the VMs. This is currently just the server'
  task :provision_vms do
    if File.exist?('../spec/fixtures/litmus_inventory.yaml')
      # Check if a server VM's already been setup
      begin
        uri = server.uri
        puts("A server VM at '#{uri}' has already been set up")
        next
      rescue TargetNotFoundError
        puts 'Server VM not yet set up.' # Pass-thru, this means that we haven't set up the server VM
      end
    end

    provision_list = ENV['PROVISION_LIST'] || 'acceptance'
    Rake::Task['litmus:provision_list'].invoke(provision_list)
  end

  # TODO: This should be refactored to use the https://github.com/puppetlabs/puppetlabs-peadm
  # module for PE setup
  desc 'Sets up PE on the server'
  task :setup_pe do
    include ::BoltSpec::Run
    inventory_hash = inventory_hash_from_inventory_file
    target_nodes = find_targets(inventory_hash, 'ssh_nodes')

    config = { 'modulepath' => File.join(Dir.pwd, 'spec', 'fixtures', 'modules') }

    bolt_result = run_plan('common_events::acceptance::pe_server', {}, config: config, inventory: inventory_hash.clone)
  end

  desc 'Installs the module on the server'
  task :install_module do
    Rake::Task['litmus:install_module'].invoke(server.uri)
  end

  desc 'Reloads puppetserver on the server'
  task :reload_module do
    result = server.run_shell('/opt/puppetlabs/bin/puppetserver reload').stdout.chomp
    puts "Error: #{result}" unless result == ''
  end

  desc 'Gets the puppetserver logs for service now'
  task :get_logs do
    puts server.run_shell('tail -500 /var/log/puppetlabs/puppetserver/puppetserver.log').stdout.chomp
  end

  desc 'Do an agent run'
  task :agent_run do
    puts server.run_shell('puppet agent -t').stdout.chomp
  end

  desc 'Runs the tests'
  task :run_tests do
    rspec_command  = 'bundle exec rspec ./spec/acceptance --format documentation'
    rspec_command += ' --format RspecJunitFormatter --out rspec_junit_results.xml' if ENV['CI'] == 'true'
    puts("Running the tests ...\n")
    unless system(rspec_command)
      # system returned false which means rspec failed. So exit 1 here
      exit 1
    end
  end

  desc 'Set up the test infrastructure'
  task :setup do
    tasks = [
      :provision_vms,
      :setup_pe,
      :install_module,
    ]

    tasks.each do |task|
      task = "acceptance:#{task}"
      puts("Invoking #{task}")
      Rake::Task[task].invoke
      puts("\n")
    end
  end

  desc 'Teardown the setup'
  task :tear_down do
    puts("Tearing down the test infrastructure ...\n")
    Rake::Task['litmus:tear_down'].invoke(server.uri)
  end

  desc 'Task for CI'
  task :ci_run_tests do
    begin
      Rake::Task['acceptance:setup'].invoke
      Rake::Task['acceptance:run_tests'].invoke
    ensure
      Rake::Task['acceptance:tear_down'].invoke
    end
  end
end
