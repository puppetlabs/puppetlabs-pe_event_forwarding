# puppetlabs-common_integration_events

The Common Integration Events module collates different PuppetEnterprise API data sources into a common reporting Gem.

PROTOTYPE!

#### Table of Contents

1. [Pre-reqs](#pre-reqs)
2. [Setup](#setup)
    * [Events](#events)
    * [Incidents](#incidents)
3. [Troubleshooting](#troubleshooting)
4. [Development](#development)
5. [Release-Process](#Release-Process)

## Pre-reqs

* Puppet Enterprise version 2019.8.1 (LTS) or newer

## Setup

1. Install the `puppetlabs-common_integration_events` module on your Puppet server.


## Development

### Setup

```bash
bundle install
bundle exec rake spec_prep
```

### Launching the dev framework

```bash
bundle exec rake launch:provision_vms
bundle exec rake launch:setup_pe
bundle exec rake launch:reload_pe
bundle exec rake launch:install_agent
bundle exec rake launch:puppet_agent_run
```

### Scraping the orchestrator API

First some jobs/tasks must be executed on the PE console that was created in the launch step. Do this by going to the tasks sub menu and running something simple on all nodes like "facts".

```bash
PT_PE_CONSOLE=<The PE Console FQDN> bundle exec ruby tasks/orchestrator.rb
```

### Release Process
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