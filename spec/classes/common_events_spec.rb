# frozen_string_literal: true

require 'spec_helper'

describe 'common_events' do
  let(:pre_condition) do
    <<-MANIFEST
    define cron (
      Optional[Any] $ensure  = undef,
      Optional[Any] $path  = undef,
      Optional[Any] $command  = undef,
      Optional[Any] $user  = undef,
      Optional[Any] $minute  = undef,
    ) {}
    MANIFEST
  end

  let(:params) do
    {
      pe_token: 'blah',
    }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }
    end
  end
end
