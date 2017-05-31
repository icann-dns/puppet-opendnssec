require 'spec_helper'

describe 'opendnssec::addns' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera
  let(:node) { 'opendnssec::addns.example.com' }

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
      #:tsigs => {},
      #:xfers_in => {},
      #:xfers_out => {},
      #:xferout_enabled => true,
      #:addns_file => '/etc/opendnssec/addns.xml',

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context 'on #{os}' do
      let(:facts) do
        facts
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_concat('/etc/opendnssec/addns.xml').with(
            owner:  'root',
            group:  'root',
          )
        end
        it do
          is_expected.to contain_concat__fragment('addns_header').with(
            target:  '/etc/opendnssec/addns.xml',
            content:  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!-- File managed by puppet DO NOT EDIT -->\n<Adapter>\n  <DNS>\n",
            order:  '01',
          )
        end
        it do
          is_expected.to contain_concat__fragment('addns_footer').with(
            target:  '/etc/opendnssec/addns.xml',
            content:  "  </DNS>\n</Adapter>\n",
            order:  '99',
          )
        end
        it do
          is_expected.to contain_concat__fragment('xfer_in_header').with(
            target:  '/etc/opendnssec/addns.xml',
            content:  "\n    <Inbound>\n",
            order:  '20',
          )
        end
        it do
          is_expected.to contain_concat__fragment('xfer_in_footer').with(
            target:  '/etc/opendnssec/addns.xml',
            content:  "    </Inbound>\n",
            order:  '29',
          )
        end
        it do
          is_expected.to contain_concat__fragment('xfer_out_header').with(
            target:  '/etc/opendnssec/addns.xml',
            content:  "\n    <Outbound>\n",
            order:  '30',
          )
        end
        it do
          is_expected.to contain_concat__fragment('xfer_out_footer').with(
            target:  '/etc/opendnssec/addns.xml',
            content:  "    </Outbound>\n",
            order:  '39',
          )
        end
        it do
          is_expected.to contain_exec(
            'Forcing ods-ksmutil to update after modifying addns.xml'
          ).with(
            command:  '/usr/bin/ods-ksmutil update all',
            user:  'root',
            refreshonly:  true,
            subscribe:  'Concat[/etc/opendnssec/addns.xml]',
          )
        end
      end
      describe 'Change Defaults' do
        context 'tsigs' do
          before { params.merge!(tsigs: {}) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'xfers_in' do
          before { params.merge!(xfers_in: {}) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'xfers_out' do
          before { params.merge!(xfers_out: {}) }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'xferout_enabled' do
          before { params.merge!(xferout_enabled: false) }
          it { is_expected.to compile }
          it { is_expected.not_to contain_concat__fragment('xfer_out_header') }
          it { is_expected.not_to contain_concat__fragment('xfer_out_footer') }
        end
        context 'addns_file' do
          before { params.merge!(addns_file: '/foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_concat('/foobar') }
          it do
            is_expected.to contain_concat__fragment('addns_header').with_target(
              '/foobar',
            )
          end
          it do
            is_expected.to contain_concat__fragment('addns_footer').with_target(
              '/foobar',
            )
          end
          it do
            is_expected.to contain_concat__fragment('xfer_in_header').with_target(
              '/foobar',
            )
          end
          it do
            is_expected.to contain_concat__fragment('xfer_in_footer').with_target(
              '/foobar',
            )
          end
          it do
            is_expected.to contain_concat__fragment('xfer_out_header').with_target(
              '/foobar',
            )
          end
          it do
            is_expected.to contain_concat__fragment('xfer_out_footer').with_target(
              '/foobar',
            )
          end
          it do
            is_expected.to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns.xml'
            ).with_subscribe('Concat[/foobar]')
          end
        end
        context 'change user' do
          let(:pre_condition) { 'class {\'::opendnssec\': user => \'foobar\' }' }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat(
              '/etc/opendnssec/addns.xml'
            ).with_owner('foobar')
          end
          it do
            is_expected.to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns.xml',
            ).with_user('foobar')
          end
        end
        context 'change group' do
          let(:pre_condition) { 'class {\'::opendnssec\': group => \'foobar\' }' }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat(
              '/etc/opendnssec/addns.xml'
            ).with_group('foobar')
          end
        end
        context 'change enabled' do
          let(:pre_condition) do
            'class {\'::opendnssec\': enabled => false }'
          end
          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns.xml'
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
              'Forcing ods-ksmutil to update after modifying addns.xml'
            )
          end
        end
      end
      describe 'check bad type' do
        context 'tsigs' do
          before { params.merge!(tsigs: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'xfers_in' do
          before { params.merge!(xfers_in: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'xfers_out' do
          before { params.merge!(xfers_out: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'xferout_enabled' do
          before { params.merge!(xferout_enabled: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'addns_file' do
          before { params.merge!(addns_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
