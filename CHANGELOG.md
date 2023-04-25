# Change log

All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [Unreleased](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding)

### Fixed

- Internal `base_path` function now removes any trailing slash (`/`) from user provided config directories. [#118](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/118)

[Current Diff](https://github.com/puppetlabs/puppetlabs-splunk_hec/compare/v1.1.0..main)

## [v2.0.0](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v2.0.0) (2023-05-XX)

### Fixed

- Utilize kwargs over positional args for Ruby 3 compatibility. [#119](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/119)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.1.0..v2.0.0)

## [v1.1.1](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.1.1) (2023-01-31)

### Fixed

- User for the crontab entry now defaults to internal `$owner` variable. [#115](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/115)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.5..v1.1.0)

## [v1.1.0](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.1.0) (2022-03-10)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.5..v1.1.0)

### Added

- Added a parameter to disable rbac events for increased performance for users with a large amount of rbac events. [#106](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/106)

### Fixed

- Support logfile_basepath and lockdir_bathpath outside of /etc/puppetlabs. [#107](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/107)

- Properly support custom confdirs. [#108](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/108)

## [v1.0.5](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.0.5) (2022-02-14)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.4..v1.0.5)

- Fixed bug where stacking cron jobs can delete lockfiles that belong to another job. [#104](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/104)

## [v1.0.4](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.0.4) (2022-01-04)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.3..v1.0.4)

- Add debugging messages to make troubleshooting easier for customers and support [#100](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/100)

## [v1.0.3](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.0.3) (2021-11-09)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.2..v1.0.3)

- Document Forwarding from Non Server Nodes [#93](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/93)

## [v1.0.2](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.0.2) (2021-10-04)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.1..v1.0.2)

### Added

- (MAINT) Readme update to document Sensitive data typed `pe_password` parameter. [#90](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/90)

## [v1.0.1](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.0.1) (2021-09-30)

[Full Changelog](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/compare/v1.0.0..v1.0.1)

### Fixed

- Project URL. [#86](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/pull/86)

## [v1.0.1](https://github.com/puppetlabs/puppetlabs-pe_event_forwarding/tree/v1.0.0) (2021-09-29)

Initial Release
