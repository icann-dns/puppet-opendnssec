# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::zone' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_zone' }

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
      # signer_policy: 'test_signer_policy',
      # :order => '10',
      # :adapter_base_dir => '/var/lib/opendnssec',
      # :adapter_signer_conf => :undef,
      # :adapter_input_file => :undef,
      # :adapter_output_file => :undef,
      # :adapter_input_type => 'DNS',
      # :adapter_output_type => 'DNS',
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let(:pre_condition) do
    <<-EOF
    class { '::opendnssec':
      policies => {'default' => {} },
      remotes  => {
        'master' => { 'address4' => '192.0.2.1' },
        'provide_xfr' => { 'address4' => '192.0.2.2' },
      },
    }
    EOF
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/addns-default.xml.tmp'
          )
        end
        it do
          is_expected.to contain_exec(
            'Forcing ods-ksmutil to update after modifying addns-default.xml'
          )
        end
        it do
          is_expected.to contain_concat__fragment('zone_test_zone').with(
            target: '/etc/opendnssec/zonelist.xml',
            order: '10'
          ).with_content(
            %r{<Zone\sname="test_zone">
            \s+<Policy>default</Policy>
            \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
            \s+<Adapters>
            \s+<Input>
            \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
            \s+</Input>
            \s+<Output>
            \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
            \s+</Output>
            \s+</Adapters>
            \s+</Zone>
            }x
          )
        end
      end
      describe 'Change Defaults' do
        context 'signer_policy' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              policies => {'foobar' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          before { params.merge!(signer_policy: 'foobar') }
          it { is_expected.to compile }
          it { is_expected.to contain_concat__fragment('policy_foobar') }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>foobar</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'masters' do
          before { params.merge!(masters: ['master']) }
          it { is_expected.to compile }
          it { is_expected.to contain_opendnssec__addns('test_zone-masters') }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_zone-masters.xml.tmp'
            )
          end
          it do
            is_expected.to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_zone-masters.xml'
            )
          end
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-test_zone-masters.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'provide_xfrs' do
          before { params.merge!(provide_xfrs: ['provide_xfr']) }
          it { is_expected.to compile }
          it { is_expected.to contain_opendnssec__addns('test_zone-provide_xfrs') }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_zone-provide_xfrs.xml.tmp'
            )
          end
          it do
            is_expected.to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_zone-provide_xfrs.xml'
            )
          end
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-test_zone-provide_xfrs.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'masters and provide_xfrs' do
          before { params.merge!(masters: ['master'], provide_xfrs: ['provide_xfr']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-test_zone-masters.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-test_zone-provide_xfrs.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'order' do
          before { params.merge!(order: '20') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_order('20')
          end
        end
        context 'adapter_base_dir File input' do
          before do
            params.merge!(
              adapter_base_dir: '/foobar',
              adapter_input_type: 'File',
              zone_content: 'bla'
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/foobar/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="File">/foobar/unsigned/test_zone</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_base_dir File output' do
          before do
            params.merge!(
              adapter_base_dir: '/foobar',
              adapter_output_type: 'File'
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/foobar/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="File">/foobar/signed/test_zone</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_base_dir' do
          before { params.merge!(adapter_base_dir: '/foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/foobar/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_signer_conf' do
          before { params.merge!(adapter_signer_conf: '/foobar') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/foobar</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_input_file' do
          before do
            params.merge!(
              adapter_input_file: '/foobar',
              adapter_input_type: 'File',
              zone_content: 'bla'
            )
          end
          it { is_expected.to compile }
          # Add Check to validate change was successful
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="File">/foobar</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_output_file' do
          before do
            params.merge!(
              adapter_output_file: '/foobar',
              adapter_output_type: 'File'
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="File">/foobar</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_input_type' do
          before do
            params.merge!(adapter_input_type: 'File', zone_content: 'bla')
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="File">/var/lib/opendnssec/unsigned/test_zone</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
        context 'adapter_output_type' do
          before { params.merge!(adapter_output_type: 'File') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'zone_test_zone'
            ).with_content(
              %r{<Zone\sname="test_zone">
              \s+<Policy>default</Policy>
              \s+<SignerConfiguration>/var/lib/opendnssec/signconf/test_zone.xml</SignerConfiguration>
              \s+<Adapters>
              \s+<Input>
              \s+<Adapter\stype="DNS">/etc/opendnssec/addns-default.xml</Adapter>
              \s+</Input>
              \s+<Output>
              \s+<Adapter\stype="File">/var/lib/opendnssec/signed/test_zone</Adapter>
              \s+</Output>
              \s+</Adapters>
              \s+</Zone>
              }x
            )
          end
        end
      end
      describe 'check bad type' do
        context 'signer_policy' do
          before { params.merge!(signer_policy: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'order' do
          before { params.merge!(order: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'adapter_base_dir' do
          before { params.merge!(adapter_base_dir: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'adapter_signer_conf' do
          before { params.merge!(adapter_signer_conf: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'adapter_input_file' do
          before { params.merge!(adapter_input_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'adapter_output_file' do
          before { params.merge!(adapter_output_file: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'adapter_input_type' do
          before { params.merge!(adapter_input_type: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'adapter_output_type' do
          before { params.merge!(adapter_output_type: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
