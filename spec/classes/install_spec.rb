# frozen_string_literal: true

require 'spec_helper'

describe 'common_events::install' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:pre_condition) do
        <<-PRE_COND
          class {'common_events':
            pe_token => 'blah',
          }
      PRE_COND
      end
      let(:confdir) { Puppet.settings.setting('confdir').value }
      let(:facts) do
        facts.merge(pe_server_version: '2019.8.7')
      end

      it {
        is_expected.to contain_file("#{confdir}/common_events")
          .with(
          ensure: 'directory',
        )
      }

      it {
        is_expected.to contain_file("#{confdir}/common_events/collect_api_events.rb")
          .with(
          ensure: 'file',
          require: "File[#{confdir}/common_events]",
        )
      }

      it {
        is_expected.to contain_file("#{confdir}/common_events/events_collection.yaml")
          .with(
          ensure: 'file',
          require: "File[#{confdir}/common_events]",
        )
      }

      it {
        is_expected.to contain_cron('collect_common_events')
          .with_command("#{confdir}/common_events/collect_api_events.rb" \
          " #{confdir}/common_events" \
          " #{FULL_MODULE_PATH}" \
          " #{confdir}/common_events")
      }
    end
  end
end
