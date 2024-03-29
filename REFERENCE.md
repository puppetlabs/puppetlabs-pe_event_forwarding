# Reference

<!-- DO NOT EDIT: This document was generated by Puppet Strings -->

## Table of Contents

### Classes

#### Public Classes

* [`pe_event_forwarding`](#pe_event_forwarding): Create the required cron job and scripts for sending Puppet Events

#### Private Classes

* `pe_event_forwarding::v2_cleanup`: A subclass to remove old settings file.

### Functions

* [`pe_event_forwarding::base_path`](#pe_event_forwarding--base_path): This custom function returns the base path of any given string argument. If a desired path is not passed in, it will match the default str ar
* [`pe_event_forwarding::secure`](#pe_event_forwarding--secure): Custom function to mark sensitive data utilized by this module as Sensitive types in the Puppet language. Sensitive data is redacted from Pup

### Tasks

* [`activities`](#activities): This task scrapes the PE activity API for all events.
* [`orchestrator`](#orchestrator): This task scrapes the orchestrator for jobs

### Plans

* [`pe_event_forwarding::acceptance::pe_server`](#pe_event_forwarding--acceptance--pe_server): Install PE Server
* [`pe_event_forwarding::acceptance::provision_machines`](#pe_event_forwarding--acceptance--provision_machines): Provisions machines

## Classes

### <a name="pe_event_forwarding"></a>`pe_event_forwarding`

This class will create the cron job that executes the event management script.
It also creates the event management script in the required directory.

#### Examples

##### 

```puppet
include pe_event_forwarding
```

#### Parameters

The following parameters are available in the `pe_event_forwarding` class:

- [Reference](#reference)
  - [Table of Contents](#table-of-contents)
    - [Classes](#classes)
      - [Public Classes](#public-classes)
      - [Private Classes](#private-classes)
    - [Functions](#functions)
    - [Tasks](#tasks)
    - [Plans](#plans)
  - [Classes](#classes-1)
    - [`pe_event_forwarding`](#pe_event_forwarding)
      - [Examples](#examples)
        - [](#)
      - [Parameters](#parameters)
        - [`pe_username`](#pe_username)
        - [`pe_password`](#pe_password)
        - [`pe_token`](#pe_token)
        - [`pe_console`](#pe_console)
        - [`disabled`](#disabled)
        - [`cron_minute`](#cron_minute)
        - [`cron_hour`](#cron_hour)
        - [`cron_weekday`](#cron_weekday)
        - [`cron_month`](#cron_month)
        - [`cron_monthday`](#cron_monthday)
        - [`timeout`](#timeout)
        - [`log_path`](#log_path)
        - [`lock_path`](#lock_path)
        - [`confdir`](#confdir)
        - [`api_page_size`](#api_page_size)
        - [`log_level`](#log_level)
        - [`log_rotation`](#log_rotation)
        - [`skip_events`](#skip_events)
        - [`skip_jobs`](#skip_jobs)
  - [Functions](#functions-1)
    - [`pe_event_forwarding::base_path`](#pe_event_forwardingbase_path)
      - [Examples](#examples-1)
        - [Calling the function](#calling-the-function)
      - [`pe_event_forwarding::base_path(Any $str, Any $path)`](#pe_event_forwardingbase_pathany-str-any-path)
        - [Examples](#examples-2)
          - [Calling the function](#calling-the-function-1)
        - [`str`](#str)
        - [`path`](#path)
    - [`pe_event_forwarding::secure`](#pe_event_forwardingsecure)
      - [`pe_event_forwarding::secure(Hash $secrets)`](#pe_event_forwardingsecurehash-secrets)
        - [`secrets`](#secrets)
  - [Tasks](#tasks-1)
    - [`activities`](#activities)
      - [Parameters](#parameters-1)
        - [`pe_console`](#pe_console-1)
        - [`pe_username`](#pe_username-1)
        - [`pe_password`](#pe_password-1)
    - [`orchestrator`](#orchestrator)
      - [Parameters](#parameters-2)
        - [`console_host`](#console_host)
        - [`username`](#username)
        - [`password`](#password)
        - [`token`](#token)
        - [`operation`](#operation)
        - [`body`](#body)
        - [`nodes`](#nodes)
  - [Plans](#plans-1)
    - [`pe_event_forwarding::acceptance::pe_server`](#pe_event_forwardingacceptancepe_server)
      - [Examples](#examples-3)
        - [](#-1)
      - [Parameters](#parameters-3)
        - [`version`](#version)
        - [`pe_settings`](#pe_settings)
    - [`pe_event_forwarding::acceptance::provision_machines`](#pe_event_forwardingacceptanceprovision_machines)
      - [Parameters](#parameters-4)
        - [`using`](#using)
        - [`image`](#image)

##### <a name="-pe_event_forwarding--pe_username"></a>`pe_username`

Data type: `Optional[String]`

PE username

Default value: `undef`

##### <a name="-pe_event_forwarding--pe_password"></a>`pe_password`

Data type: `Optional[String]`

PE password

Default value: `undef`

##### <a name="-pe_event_forwarding--pe_token"></a>`pe_token`

Data type: `Optional[String]`

PE token

Default value: `undef`

##### <a name="-pe_event_forwarding--pe_console"></a>`pe_console`

Data type: `String`

PE console

Default value: `'localhost'`

##### <a name="-pe_event_forwarding--disabled"></a>`disabled`

Data type: `Boolean`

When true, removes cron job

Default value: `false`

##### <a name="-pe_event_forwarding--cron_minute"></a>`cron_minute`

Data type: `String`

Sets cron minute (0-59)

Default value: `'*/2'`

##### <a name="-pe_event_forwarding--cron_hour"></a>`cron_hour`

Data type: `String`

Sets cron hour (0-23)

Default value: `'*'`

##### <a name="-pe_event_forwarding--cron_weekday"></a>`cron_weekday`

Data type: `String`

Sets cron day of the week (0-6)

Default value: `'*'`

##### <a name="-pe_event_forwarding--cron_month"></a>`cron_month`

Data type: `String`

Sets cron month (1-12)

Default value: `'*'`

##### <a name="-pe_event_forwarding--cron_monthday"></a>`cron_monthday`

Data type: `String`

Sets cron day of the month (1-31)

Default value: `'*'`

##### <a name="-pe_event_forwarding--timeout"></a>`timeout`

Data type: `Optional[Integer]`

Optional timeout limit for connect, read, and ssl sessions
When set to `undef` the default of 60 seconds will be used

Default value: `undef`

##### <a name="-pe_event_forwarding--log_path"></a>`log_path`

Data type: `Optional[String]`

Should be a directory; base path to desired location for log files
`/pe_event_forwarding/pe_event_forwarding.log` will be appended to this param

Default value: `undef`

##### <a name="-pe_event_forwarding--lock_path"></a>`lock_path`

Data type: `Optional[String]`

Should be a directory; base path to desired location for lock file
`/pe_event_forwarding/cache/state/events_collection_run.lock` will be appended to this param

Default value: `undef`

##### <a name="-pe_event_forwarding--confdir"></a>`confdir`

Data type: `Optional[String]`

Path to directory where pe_event_forwarding exists

Default value: `undef`

##### <a name="-pe_event_forwarding--api_page_size"></a>`api_page_size`

Data type: `Optional[Integer]`

Sets max number of events retrieved per API call

Default value: `undef`

##### <a name="-pe_event_forwarding--log_level"></a>`log_level`

Data type: `Enum['DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL']`

Determines the severity of logs to be written to log file:
 - level debug will only log debug-level log messages
 - level info will log info, warn, and fatal-level log messages
 - level warn will log warn and fatal-level log messages
 - level fatal will only log fatal-level log messages

Default value: `'WARN'`

##### <a name="-pe_event_forwarding--log_rotation"></a>`log_rotation`

Data type: `Enum['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']`

Determines rotation time for log files

Default value: `'NONE'`

##### <a name="-pe_event_forwarding--skip_events"></a>`skip_events`

Data type: `Optional[Array]`

Array of event types that should be skipped during event collection from the Activity API.
  Acceptable values are: `['classifier','code-manager','pe-console','rbac']`

Default value: `undef`

##### <a name="-pe_event_forwarding--skip_jobs"></a>`skip_jobs`

Data type: `Optional[Boolean]`

When true, event collection from the Orchestrator API is disabled.

Default value: `undef`

## Functions

### <a name="pe_event_forwarding--base_path"></a>`pe_event_forwarding::base_path`

Type: Ruby 4.x API

This custom function returns the base path of any given string
argument. If a desired path is not passed in, it will match the
default str argument up to `puppetlabs`.

#### Examples

##### Calling the function

```puppet
pe_event_forwarding::base_path(default_path, desired_path)
```

#### `pe_event_forwarding::base_path(Any $str, Any $path)`

This custom function returns the base path of any given string
argument. If a desired path is not passed in, it will match the
default str argument up to `puppetlabs`.

Returns: `String` Returns a string

##### Examples

###### Calling the function

```puppet
pe_event_forwarding::base_path(default_path, desired_path)
```

##### `str`

Data type: `Any`

The backup path to set; default

##### `path`

Data type: `Any`

The desired path

### <a name="pe_event_forwarding--secure"></a>`pe_event_forwarding::secure`

Type: Ruby 4.x API

Custom function to mark sensitive data utilized by
this module as Sensitive types in the Puppet language.
Sensitive data is redacted from Puppet logs and reports.

#### `pe_event_forwarding::secure(Hash $secrets)`

Custom function to mark sensitive data utilized by
this module as Sensitive types in the Puppet language.
Sensitive data is redacted from Puppet logs and reports.

Returns: `Any`

##### `secrets`

Data type: `Hash`



## Tasks

### <a name="activities"></a>`activities`

This task scrapes the PE activity API for all events.

**Supports noop?** false

#### Parameters

##### `pe_console`

Data type: `String[1]`

The FQDN of the PE console

##### `pe_username`

Data type: `Optional[String[1]]`

A PE user name

##### `pe_password`

Data type: `Optional[String[1]]`

The PE console password

### <a name="orchestrator"></a>`orchestrator`

This task scrapes the orchestrator for jobs

**Supports noop?** false

#### Parameters

##### `console_host`

Data type: `String[1]`

The FQDN of the PE console

##### `username`

Data type: `Optional[String[1]]`

A PE user name

##### `password`

Data type: `Optional[String[1]]`

The PE console password

##### `token`

Data type: `Optional[String[1]]`

An Auth token for a user

##### `operation`

Data type: `Enum['run_facts_task', 'run_job', 'get_job', 'current_job_count', 'get_jobs']`

The task to perform in the orchestrator.

##### `body`

Data type: `Optional[String[1]]`

Data to send to the orchestrator for the operation

##### `nodes`

Data type: `Optional[String[1]]`

Nodes to run facts on. Different from console host target

## Plans

### <a name="pe_event_forwarding--acceptance--pe_server"></a>`pe_event_forwarding::acceptance::pe_server`

Install PE Server

#### Examples

##### 

```puppet
pe_event_forwarding::acceptance::pe_server
```

#### Parameters

The following parameters are available in the `pe_event_forwarding::acceptance::pe_server` plan:

* [`version`](#-pe_event_forwarding--acceptance--pe_server--version)
* [`pe_settings`](#-pe_event_forwarding--acceptance--pe_server--pe_settings)

##### <a name="-pe_event_forwarding--acceptance--pe_server--version"></a>`version`

Data type: `Optional[String]`

PE version

Default value: `'2021.7.5'`

##### <a name="-pe_event_forwarding--acceptance--pe_server--pe_settings"></a>`pe_settings`

Data type: `Optional[Hash]`

Hash with key `password` and value of PE console password for admin user

Default value: `{ password => 'puppetlabspie', configure_tuning => false }`

### <a name="pe_event_forwarding--acceptance--provision_machines"></a>`pe_event_forwarding::acceptance::provision_machines`

Provisions machines

#### Parameters

The following parameters are available in the `pe_event_forwarding::acceptance::provision_machines` plan:

* [`using`](#-pe_event_forwarding--acceptance--provision_machines--using)
* [`image`](#-pe_event_forwarding--acceptance--provision_machines--image)

##### <a name="-pe_event_forwarding--acceptance--provision_machines--using"></a>`using`

Data type: `Optional[String]`

provision service

Default value: `'abs'`

##### <a name="-pe_event_forwarding--acceptance--provision_machines--image"></a>`image`

Data type: `Optional[String]`

os image

Default value: `'centos-7-x86_64'`