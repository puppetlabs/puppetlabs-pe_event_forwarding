# puppetlabs-pe_event_forwarding

#### Table of Contents


1. [Intro](#intro)
2. [Usage](#usage)
3. [How it works](#how-it-works)
4. [Writing an Event Forwarding Processor](#writing-an-event-forwarding-processor)
5. [Installing A Processor](#installing-a-processor)
6. [Token vs Username Password Authentication](#token-vs-username-password-authentication)
7. [Resources Placed On The Machine](#resources-placed-on-the-machine)
8. [Logging](#logging)
9. [Advanced Configuration Options](#advanced-configuration-options)

## Intro

This module gathers events from the [Puppet Jobs API][1] and the [Activities API][2] using a script executed by a cron job. This data is provided to any available processor scripts during each run. The scripts are provided by any modules that want to make use of this data such as the [puppetlabs-splunk_hec][3] module. These processor scripts then handle the data they are given and forward it on to their respective platforms.


## Usage

1. Install the module in your environment

2. Classify a node with the `pe_event_forwarding` class and provide a value for the `pe_token` parameter. We recommend providing an api token generated for a console user created for use with this module. See [rbac token vs username/password ](#token-vs-username-password-authentication) below for details. Also see [Advanced Configuration Options](#advanced-configuration-options) below for details on other configuration options.

3. Install a module that implements a PE Event Forwarding processor such as the [Splunk_hec][3] module, and enable its Event Forwarding feature as detailed in that module's documentation.

### Forwarding from non server nodes

This module is capable of gathering events data and invoking processors from non Puppet Server nodes. If you want do to this, ensure that you set the `pe_console` parameter to the fully qualified domain name of the Puppet Server running the Orchestrator and Activies APIs. Often using the `$settings::server` for this parameter will work.

## How it works

1. The cron job executes the collection script at the configured interval.

2. The script determines if this is the first time it is running on the system by looking for a file written by the script to track which events have already been sent (`pe_event_forwarding_indexes.yaml`).

3. If this is the first time the script is executed it will write the number of events avaialable in the APIs to the indexes file and then shut down. This is to prevent the first execution of this script from attempting to send every event in the system on the first run, all at the same time. Doing so could cause performance issues for the Puppet Server.

4. If this is not the first time running, it will gather all events that have occurred since the last time the script was run.

5. When the events data is collected it will search for any available processors in the `processors.d` directory.

6. Each processor that is found will be invoked by executing the script or executable and passing the path on disk to a temporary file that contains the events to be processed.

7. When the processor exits execution, any strings that it has passed back to the collection script on `STDOUT` or `STDERR` will be logged to the collection script's log file, along with the exit code.

8. The collection script will write to the indexes tracking file the new index numbers for each API to ensure that on the next execution it knows how many events are new and need to be processed.

9. The script exits.

## Compatible PE Versions

This module is compatible with PE versions in the 2019 range starting at 2019.8.7 and above, and then 2021 versions from 2021.2 and above.

Versions in the PE 2019 series below 2019.8.7 and in the 2021 series in versions below 2021.2 did not recieve an update to some of the API methods in PE that are required for this module to function properly.

## Writing an Event Forwarding Processor

An event forwarding processor is any script or executable binary that:

- Is placed in the `pe_event_forwarding/processors.d` directory. See [Resources Placed On The Machine][5] for details.
- Has execute permissions
- Can be executed by calling the name of the file without the need to pass the filename to another executable. This means that script file processors should have a shebang at the top giving the path to the correct interpreter.
- Accepts a commandline parameter giving the path to a temporary file containing the data to process

A processor should implement the following workflow when invoked

1. Accept the commandline path to a temporary data file

2. Read the data file and parse into a format most appropriate for the processor's purposes. The file itself will be in JSON format with the following basic structure:

```JSON
{
    "orchestrator": {
        "api_total_count": 50,
        "events": [
            ...
        ]
    },
    "classifier": {
        "api_total_count": 50,
        "events": [
            ...
        ]
    },
    "rbac": {
        "api_total_count": 50,
        "events": [
            ...
        ]
    },
    "pe-console": {
        "api_total_count": 50,
        "events": [
            ...
        ]
    },
    "code-manager": {
        "api_total_count": 50,
        "events": [
            ...
        ]
    }
}
```

Processor developers can regard the top level keys as the basic event types to handle. See the following links for detailed information about the format of the data in each event type: [Orchestrator Response Format][6] for the first key `orchestrator`, and the [Activity API Response Format][7] for the remaining event types in the document. However, note that this module has normalized the name of the key that holds the data relevent event data.

For the `orchestrator` type, the key we are calling `events` is called `items` in the [Orchestrator Response Format][6]

For the remaining types, the key we are calling `events` is called `commits` in the [Activity API Response Format][7] documentation.

The key names are normalized in this module's output to make it easier for processors developers to iterate over the event types, without having to create separate code paths for handling Orchestrator 'items' vs the other data type's 'commits'.

In processor code example given below you will see how normalizing the key names make it easier to write a processor.

Below is a code example in Ruby showing a very basic PE Event Forwarding processor.

```ruby
#!/opt/puppetlabs/puppet/bin/ruby

# Library files with helper functions can be placed in sub directories of processors.d
require_relative './module_name/support_file'

# Receive the path to the temp file on the commandline
data_file_path = ARGV[0]

# Parse the file from JSON into a Ruby Hash object
data = JSON.parse(data_file_path)

# Create an empty array to collect the events
events = []

# Iterate over event types
['orchestrator', 'rbac', 'classifier', 'pe-console', 'code-manager'].each do |index|
    # Add each type's events to the array
    events << data[index]['events']
end

# The `data` object now contains an array with all of the different API's events collected into a single array.
# In a real scenario, a processor sending data to a platform would probably have to do at least some slight
# formatting of the data before sending to the recieving platform.
send_to_platform(data)
```


**NOTE:** Currently processor execution is not multi threaded. If your processor hangs in an infinite loop, other processors will not be executed.

A processor can emit messages to `STDOUT` and `STDERR`. Those messages will be collected and logged to this module's log file at the end of an execution. Messages emitted to `STDOUT` are logged at the `DEBUG` log level, and messages on `STDERR` are written at the `WARN` level.

A processor can also exit with custom exit codes. If a processor needs to log its exit code, it will need to emit a message on `STDERR`. Processors that exit with no message on `STDERR` are considered to have exited normally, and the exit code is not recorded.

## Installing A Processor

Any module that implements a PE Event Forwarding processor must ensure its processor is correctly placed in the `processors.d` directory, so that it can be found and executed.

To do that

1. Save the processor to either the `files` or `templates` sub directory of your module, depending on your module's needs.

2. Add a `file` resource that copies the processor to the correct path and ensures that it has the correct executable permissions.

    The path to copy into will usually be `/etc/puppetlabs/pe_event_forwarding/processors.d`. However, this is not guarenteed to be true as the path is based on the `$settings::confdir` variable, which can be changed from the default value that starts with `/etc/puppetlabs/`. To account for this, a function is provided by this module called `pe_event_forwarding::base_path()`. You can use that function to construct the base path for copying your processor into place as shown below.

    ```puppet
    $confdir_base_path = pe_event_forwarding::base_path($settings::confdir, undef)
    $processor_path = "${confdir_base_path}/pe_event_forwarding/processors.d/<processor file name>"

    File {
        owner => 'pe-puppet'
        group => 'pe-puppet'
    }

    file { $processor_path:
        ensure  => file,
        mode    => '0755',
        source  => 'puppet:///modules/<module name>/<processor file name>'
    }

    # If a processor needs library files, copy them into a sub directory of
    # `processors.d` and the processor can access them by relative path.

    # Ensure the sub directory is in place. The name of your subdirectory is arbitrary,
    # it doesn't have to be the module name, but it would help administrators keep track
    # of which modules are responsible for which files.
    file { "${confdir_base_path}/pe_event_forwarding/processors.d/<module name>":
        ensure  => directory,
    }

    # Copy the library file into place
    file { "${confdir_base_path}/pe_event_forwarding/processors.d/<module name>/<library file name>":
        ensure  => file,
        mode    => '0755',
        content => template('<module name>/<library file name>'),
        require => File["${confdir_base_path}/pe_event_forwarding/processors.d/<module name>"]
        before  => File[$processor_path]
    }
    ```

## Token vs Username Password Authentication

This module will allow administators to use `pe_username` and `pe_password` parameters for authentication to Puppet Enterprise. However, the APIs the module must access only support token authentication. To support username/password auth, every time events collection is executed, the module will access the rbac APIs and request a session token to complete the required API calls. This will result in at least 4 rbac events being generated for each run in the process of logging into the relevant APIs to gather events. These events can be safely ignored, but will result in meaningless events being generated for processing.

To prevent these unnecessary events, it is recommended that administrators create a dedicated user in the console and [generate a long lived token][4] to use with the `pe_token` parameter instead. Using a pre-generated token will prevent these unwanted events from being generated.

Also note that the `pe_password` parameter is a [`Sensitive`][8] parameter. The value for this parameter cannot be assigned through the console. You can use the `Sensitive()` function in a manifest to provide a value, or you can use [`lookup_options` in Hiera][9] to assign the value.

## Resources Placed On The Machine

When this module is classified to a Puppet Server it will create a set of resources on the system.

- A configurable cron job to periodically execute the script that gathers data and executes processors. Users can configure the cron schedule to run at the desired cadence, down to minimum one minute intervals.

- A log file usually placed at `/var/log/puppetlabs/pe_event_forwarding/pe_event_forwarding.log`. The path to this file is based on the `$settings::logdir` variable, such that if the value for this variable is changed to move the PE log files, the Event Forwarding log file will move with it.

- A lock file usually placed at `/opt/puppetlabs/pe_event_forwarding/cache/state/events_collection_run.lock`. This setting is based on the `$settings::statedir` such that if the value for `statedir` is moved, the lockfile will move with it.

- A directory for resource files based on the `$settings::confdir` variable. Usually this will be `/etc/puppetlabs/pe_event_forwarding`.

Inside that directory will be:

- The events collection script `collect_api_events.rb`.

- A configuration settings file `events_collection.yaml`.

- An index tracking file `pe_event_forwarding_indexes.yaml`.

- A sub directory for ruby class files `api`.

- A sub directory for utilities files consumed by the classes `util`

- A `processors.d` directory where third party modules will place Event Forwarding processors. Modules are allowed to create sub directories to store library files to help the processors.

## Logging

This module will handle logging it's own messages, as well as the messages emitted by the processors it invokes.

By default the log file will be placed in `/var/log/puppetlabs/pe_event_forwarding/pe_event_forwarding.log`. This path is dependenant on either the the value of `$settings::logdir`, or the `logdir` parameter for the `pe_event_forwarding` class. See below for details.

The log file is in single line json format, except for the header at the top of the file. This means that the log can be parsed line by line, and each line will be a fully formed JSON object that can be parsed for processing.

The default log level is `WARN`.

## Advanced Configuration Options

`pe_console`

The PE Event Forwarding module is capable of running on any Linux machine in your estate. However, it assumes by default that it has been classified on the primary Puppet Server, and it will attempt to connect to the Puppet APIs on `localhost`. If you want to run event collection from another machine, you will have to set this variable to the host name of the machine running the PE APIs. If your PE instance is behind a load balancer or some other more complex configuration, set this variable to the DNS host name you would use for getting to the console in your browser.

--------------------------------------------------------------------------------

`disabled`

Setting this variable to true will prevent events collection from executing. No further events will gathered or sent by any processor until the parameter is removed or set to `true`. It will do this by removing the cron job that executes the events collection script. This is intended for use during maintenance windows of either PE or the recieving platforms, or for any other reason an administrator might want to stop sending events. Simply removing this class from a node configuration would not be enough to stop sending events.

--------------------------------------------------------------------------------

`disable_rbac`

Setting this variable to true will skip all rbac events. This is useful for instances where there is a large enough quantity of rbac data to create a performance issue. When disabled, the rbac index will show as `-1` in the `pe_event_forwarding_indexes.yaml` file. When re-enabling the `disable_rbac` variable, only new rbac events will be processed moving forward. It will take one run of the cron job (of the `collect_api_events.rb`) to resume event processing and recreate the rbac index. All other event types will be unaffected.

--------------------------------------------------------------------------------

`cron_[minute|hour|weekday|month|monthday]`

Use these parameters to set a custom schedule for gathering events and executing processors. This schedule is enforced for the overall PE Event Forwarding feature. This means that all processors will be executing on this schedule, and the individual platform processors have no control over how often they are invoked. The default parameter values result in a cron schedule that invokes events collection every two minutes `*/2 * * * *`. Administators can use this parameter set to reduce the cycle interval to every minute, or to increase the interval to collect less often.

The Events Collection script can detect if a previous collection cycle is not complete. If this happens the script will log a message and exit to let the previous cycle finish. The log file (see below for log file placement) logs the amount of time each collection cycle took, and this duration can be used to adjust the cron interval to an appropriate value.

--------------------------------------------------------------------------------

`log_path`

By default the log file will be placed at `/var/log/puppetlabs/pe_event_forwarding/pe_event_forwarding.log`. This path is based on the PE `$settings::logdir` path, but if a value is given to this parameter then the given value will override the default and the logfile will be placed in the directory `"${log_path}/pe_event_forwarding/pe_event_forwarding.log"`. This parameter expects to receive a path to a directory, to which the remainder of the path `/pe_event_forwarding/pe_event_forwarding.log`, will be appended and the required sub directories created.

--------------------------------------------------------------------------------

`lock_path`

By default this file will be placed at `/opt/puppetlabs/pe_event_forwarding/cache/state/events_collection_run.lock`. This path is based on the `$settings::statedir` path, but passing a value to this parameter will override that path and place the lockfile in a custom location on the system. This parameter expects to receive a path to a directory, to which the remainder of the path, `/pe_event_forwarding/cache/state/events_collection_run.lock`, will be appended and the required sub directories created.

--------------------------------------------------------------------------------

`confdir`

By default this folder will be placed at `/etc/puppetlabs/p_event_forwarding`. This setting is based on the `$settings::confdir` variable, but passing a value to this parameter will override that value and place this directory in a custom location on the system. This parameter expects a path to a directory, inside of which a sub directory `pe_event_forwarding` will be created to hold all of the required files to run events collection. See [Resources Placed On The Machine](#resources-placed-on-the-machine) for details on the files placed in this directory.

--------------------------------------------------------------------------------

`api_page_size`

The size of the pages to fetch from the PE API. All unprocessed events will still be gathered from the API on each collection cycle, but this parameter allows administrators to control the size of the individual requests to the PE API, to prevent too many events from being returned in a single API call.

--------------------------------------------------------------------------------

`log_level`

Set the verbosity of the logs written by the module. Accepts a single value, one of `DEBUG`, `INFO`, `WARN`, `ERROR` or `FATAL`.

--------------------------------------------------------------------------------

`log_rotation`

Set the interval for creating new log files. Administrators are still responsible for setting log retention policies for the system as these log files will be created at the requested interval, but will still accumulate on the drive.

<!-- Reference Links Below -->

[1]: https://puppet.com/docs/pe/2019.8/orchestrator_api_jobs_endpoint.html#get_jobs
[2]: https://puppet.com/docs/pe/2019.8/activity_api_events.html#activity-api-v2-get-events
[3]: https://forge.puppet.com/modules/puppetlabs/splunk_hec
[4]: https://puppet.com/docs/pe/2021.2/rbac_token_auth_intro.html
[5]: #resources-placed-on-the-machine
[6]: https://puppet.com/docs/pe/2019.8/orchestrator_api_jobs_endpoint.html#get_jobs-response-format
[7]: https://puppet.com/docs/pe/2019.8/activity_api_events.html#response-format
[8]: https://puppet.com/docs/puppet/7/lang_data_sensitive.html
[9]: https://puppet.com/docs/puppet/6/securing-sensitive-data.html#securing_sensitive_data-lookup-options