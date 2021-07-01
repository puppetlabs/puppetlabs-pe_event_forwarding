CONTRIBUTING
============

1. [Development](#development)
2. [Release-Process](#Release-Process)

## Development

### Setup
For setting up the local testing environment, run the following commands:
```bash
bundle install
bundle exec rake spec_prep
```

### Launching the dev framework
Run the command:
```bash
bundle exec rake acceptance:setup
```
and it will create the inventory file, provision a vm, install pe and the module on the server. If preferred, one can run each of the rake tasks manually with the following commands:

```bash
bundle exec rake acceptance:provision_vms
bundle exec rake acceptance:setup_pe
bundle exec rake acceptance:install_module
```

Other available rake tasks:
```bash
bundle exec rake acceptance:reload_module
bundle exec rake acceptance:get_logs
bundle exec rake acceptance:agent_run
```
### Tearing down the dev framework
If you don't tear down the machines, the setup will continuously add to the existing inventory file.

Run the command:
```bash
bundle exec rake acceptance:teardown
```
This will delete your machine and clear the inventory file.
### Scraping the orchestrator API

First some jobs/tasks must be executed on the PE console that was created in the launch step. Do this by going to the tasks sub menu and running something simple on all nodes like "facts".

```bash
PT_PE_CONSOLE=<The PE Console FQDN> bundle exec ruby tasks/orchestrator.rb
```

### Release Process

#### Release Module to Puppet Forge
This module is hooked up with an automatic release process using Github actions. To provoke a release simply check the module out locally, tag with the new release version, then github will promote the build to the forge.

Full process to prepare for a release:

Update metadata.json to reflect new module release version
Run `bundle exec rake changelog` to update the CHANGELOG automatically
Submit PR for changes

Create Tag on target version:
```
git tag -a v0.1.0 -m "0.1.0 Feature Release"
git push upstream --tags
```

#### Release Gem to Puppet Artifactory
You'll also need to build and push the gem (since this is both a module and gem) to artifactory. You'll need to pass your credentials as the environment variables LDAP_USERNAME and LDAP_PASSWORD. Then the artifactory_creds task will create a token for you in your .gems directory. `push_to_artifactory` will push a version of the gem consistent with the version specified in `lib/common_events_library/version.rb`.
```
bundle exec gem build common_events_library.gemspec
bundle exec rake artifactory_creds
bundle exec rake push_to_artifactory
```