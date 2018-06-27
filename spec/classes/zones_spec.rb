# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::zones' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'opendnssec::zones.example.com' }

  # below is the facts hash that gives you the ability to mock
  # facts on a per describe/context block.  If you use a fact in your
  # manifest you should mock the facts below.
  let(:facts) do
    {}
  end

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      #:zones => {},

    }
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('opendnssec::zones') }
        it do
          is_expected.to contain_concat('/etc/opendnssec/zonelist.xml').with(
            owner: 'root',
            group: 'root'
          )
        end
        it do
          is_expected.to contain_concat__fragment('zone_header').with(
            target: '/etc/opendnssec/zonelist.xml',
            content: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\n<!-- File managed by Puppet DO NOT EDIT -->\n\n<ZoneList>\n",
            order: '01'
          )
        end
        it do
          is_expected.to contain_concat__fragment('zone_footer') .with(
            target: '/etc/opendnssec/zonelist.xml',
            content: "</ZoneList>\n",
            order: '99'
          )
        end
        it do
          is_expected.to contain_exec('ods-ksmutil updated zonelist.xml').with(
            command: '/usr/bin/yes | /usr/bin/ods-ksmutil update zonelist',
            user: 'root',
            refreshonly: true,
            subscribe: 'Concat[/etc/opendnssec/zonelist.xml]'
          )
        end
      end
      describe 'Change Defaults' do
        context 'zones' do
          before { params.merge!(zones: {}) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'change user' do
          let(:pre_condition) { 'class {\'::opendnssec\': user => \'foobar\' }' }

          it { is_expected.to compile }
          it do
            is_expected.to contain_concat(
              '/etc/opendnssec/zonelist.xml'
            ).with_owner('foobar')
          end
          it do
            is_expected.to contain_exec(
              'ods-ksmutil updated zonelist.xml'
            ).with_user('foobar')
          end
        end
        context 'change group' do
          let(:pre_condition) { 'class {\'::opendnssec\': group => \'foobar\' }' }

          it { is_expected.to compile }
          it do
            is_expected.to contain_concat(
              '/etc/opendnssec/zonelist.xml'
            ).with_group('foobar')
          end
        end
        context 'change zone_file' do
          let(:pre_condition) do
            'class {\'::opendnssec\': zone_file => \'/foobar\' }'
          end

          it { is_expected.to compile }
          it { is_expected.to contain_concat('/foobar') }
          it do
            is_expected.to contain_concat__fragment('zone_header').with_target(
              '/foobar'
            )
          end
          it do
            is_expected.to contain_concat__fragment('zone_footer').with_target(
              '/foobar'
            )
          end
        end
        context 'change enabled' do
          let(:pre_condition) do
            'class {\'::opendnssec\': enabled => false }'
          end

          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'ods-ksmutil updated zonelist.xml'
            )
          end
        end
        context 'change manage_ods_ksmutil' do
          let(:pre_condition) do
            'class {\'::opendnssec\': manage_ods_ksmutil => false }'
          end

          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'ods-ksmutil updated zonelist.xml'
            )
          end
        end
      end
      describe 'check bad type' do
        context 'zones' do
          before { params.merge!(zones: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
