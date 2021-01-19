# puppetlabs-common_events

The Common Integration Events module collates different PuppetEnterprise API data sources into a common reporting Gem.

PROTOTYPE!

#### Table of Contents


1. [Intro](#intro)
2. [Usage](#usage)
3. [Pre-reqs](#pre-reqs)
4. [Setup](#setup)

## Intro

The common events library is a module makes it easier to gather events from Puppet API end points and send them to other platforms. Once the module is installed in your environment, you can create classes that wrap the API calls for you to gather the events you need.

## Usage

### Getting Orchestrator Jobs

```ruby
require 'common_events_library'
orchestrator  = Orchestrator.new(pe_console_url, username: pe_username, password: pe_password, ssl_verify: false)

# Get the last ten orchestrator jobs
response = orchestrator.get_all_jobs(offset: 0, limit: 10)
```

The code above will create an orchestrator client that can get all available jobs from the `/jobs` API endpoint. The pe username and password parameters are used in the init method of the class to automatically create an API token for use when authenticating to the API calls.

### Getting Activity Service API Events

```ruby
require 'common_events_library'
events = Events.new(pe_console_url, username: pe_username, password: pe_password, ssl_verify: false)
# Alternatively, if you wish to authenticate with a token:
events = Events.new(pe_console_url, token: pe_token, ssl_verify: false)

# Get the last ten rbac service events
response = events.get_all_events(service: 'rbac', limit: 10)
```

The code above will create an Activity Service API client that can get events from the `activity-api/v1/events` end point. The `service` parameter is the name of an Activity API `service_id` which can be any of `classifier`, `rbac`, `pe-console` or `code-manager`. If you provide a username, password, and token, the token will be used.

### Create a General Purpose HTTP Client for Sending Data

```ruby
require 'common_events_library'
splunk_client = CommonEventsHttp.new('https://splunk_instance.com', port: 8088, ssl_verify: false)

# Send an event to the splunk instance. Set the `use_raw_body` parameter if the
# body data (event_json) is already a json string. If you have a ruby object that
# response to `.to_json`, you can also use that as the post body leaving the `use_raw_body`
# parameter off in this method and the client will convert it for you
splunk_client.post_request('/services/collector', event_json, {Authorization: "Splunk #{token}"}, use_raw_body: true)
```

## Pre-reqs

* Puppet Enterprise version 2019.8.1 (LTS) or newer

## Setup

1. Install the `puppetlabs-common_events` module on your Puppet server.
    - github ref in your puppetfile
        ```
        mod 'common_events',
        :git => 'https://github.com/puppetlabs/puppetlabs-common_events'
        ```
    Once the module is installed the ruby code for the classes in the `common_events_library` gem are on the load path in Puppet code. You can then call `require 'common_events_library'` and ruby should load the classes.
