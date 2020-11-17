# common_events_library::create_scheduled_task

Before starting, ensure that if you are running these example from the module repository source code, you have run `bundle exec spec_prep` to ensure the fixtures directory is prepared with the correct file structure.

Example 1. Using a params.json file to call with the task. Take special caer to notice the `--targets localhost` port of the Bolt invocation. This task is designed to be run from a workstation machine with no Bolt inventory file. All of the information the task needs to run is in the params.json file. An example params.json file is in this folder. The example task to schedule is `enterprise_tasks::verify_node` because that task takes parameters to demonstrate that this task is capable of passing parameters to the scheduled task.

`bolt task run --format json --modulepath spec/fixtures/modules/ --targets localhost common_events_library::create_scheduled_task --params @task_params.json`

Eample 2. Calling the task with no params.json file.

`bolt task run --format json --modulepath spec/fixtures/modules/ --targets localhost common_events::create_scheduled_task task=facts username=admin password=pie interval=60 puppetserver=<Puppet server name> skip_cert_check=true`
