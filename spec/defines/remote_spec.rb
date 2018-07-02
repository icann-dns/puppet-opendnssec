# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::remote' do
  let(:title) { 'test_remote' }
  let(:facts) { {} }

  # below is a list of the resource parameters that you can override.
  # By default all non-required parameters are commented out,
  # while all required parameters will require you to add a value
  let(:params) do
    {
      address4: '192.0.2.1'
      # address6: :undef,
      # tsig: :undef,
      # tsig_name: :undef,
      # port: "53",
      # tsig_name_transfer_request: :undef,
      # tsig_name_transfer_provide: :undef,
      # tsig_name_notify_in: :undef,
      # tsig_name_notify_out: :undef,
    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let(:pre_condition) do
    <<-PUPPET_POLICY
    class {'::opendnssec':
      tsigs => { 'test_tsig' => { 'data' => 'AAAA' } }
    }
    PUPPET_POLICY
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
          ).with(
            ensure: 'file',
            owner: 'root',
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<RequestTransfer>
            \s+<Remote>
            \s+<Address>192.0.2.1</Address>
            \s+<Port>53</Port>
            \s+</Remote>
            \s+</RequestTransfer>
            }x,
          )
        end
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_notify_in.xml',
          ).with(
            ensure: 'file',
            owner: 'root',
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<AllowNotify>
            \s+<Peer>
            \s+<Prefix>192.0.2.1</Prefix>
            \s+</Peer>
            \s+</AllowNotify>
            }x,
          )
        end
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
          ).with(
            ensure: 'file',
            owner: 'root',
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<ProvideTransfer>
            \s+<Peer>
            \s+<Prefix>192.0.2.1</Prefix>
            \s+</Peer>
            \s+</ProvideTransfer>
            }x,
          )
        end
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_notify_out.xml',
          ).with(
            ensure: 'file',
            owner: 'root',
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<Notify>
            \s+<Remote>
            \s+<Address>192.0.2.1</Address>
            \s+<Port>53</Port>
            \s+</Remote>
            \s+</Notify>
            }x,
          )
        end
        it do
          is_expected.to contain_exec(
            'Forcing ods-ksmutil to update after modifying remote test_remote',
          ).with(
            command: '/usr/bin/yes | /usr/bin/ods-ksmutil update all',
            user: 'root',
            refreshonly: true,
            subscribe: [
              'File[/etc/opendnssec/remotes/test_remote_notify_out.xml]',
              'File[/etc/opendnssec/remotes/test_remote_providetransfer.xml]',
              'File[/etc/opendnssec/remotes/test_remote_notify_in.xml]',
              'File[/etc/opendnssec/remotes/test_remote_requesttransfer.xml]',
            ],
          )
        end
      end
      describe 'Change Defaults' do
        context 'address4' do
          before(:each) { params.merge!(address4: '192.0.2.255') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.255</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.255</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.255</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.255</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'address6' do
          before(:each) { params.merge!(address6: '2001:DB8::1') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'ipv6 only' do
          before(:each) { params.merge!(address4: :undef, address6: '2001:DB8::1') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'tsig' do
          before(:each) { params.merge!(tsig: 'test_tsig', tsig_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+<Key>foobar</Key>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>foobar</Key>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'tsig_name' do
          before(:each) { params.merge!(tsig_name: 'test_tsig') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+<Key>test_tsig</Key>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>test_tsig</Key>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'port' do
          before(:each) { params.merge!(port: 5353) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>5353</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>5353</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'different tsigs' do
          before(:each) do
            params.merge!(
              tsig_name_transfer_request: 'test_tsig_transfer_request',
              tsig_name_transfer_provide: 'test_tsig_transfer_provide',
              tsig_name_notify_in: 'test_tsig_notify_in',
              tsig_name_notify_out: 'test_tsig_notify_out',
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+<Key>test_tsig_transfer_request</Key>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>test_tsig_notify_in</Key>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>test_tsig_transfer_provide</Key>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+<Key>test_tsig_notify_out</Key>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
        context 'All params' do
          before(:each) do
            params.merge!(
              address6: '2001:DB8::1',
              port: 5353,
              tsig_name: 'test_tsig',
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>5353</Port>
              \s+<Key>test_tsig</Key>
              \s+</Remote>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>5353</Port>
              \s+<Key>test_tsig</Key>
              \s+</Remote>
              \s+</RequestTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>test_tsig</Key>
              \s+</Peer>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+<Key>test_tsig</Key>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x,
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>5353</Port>
              \s+</Remote>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>5353</Port>
              \s+</Remote>
              \s+</Notify>
              }x,
            )
          end
        end
      end
      describe 'check bad type' do
        context 'no address' do
          before(:each) { params.merge!(address4: nil) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'address4' do
          before(:each) { params.merge!(address4: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'address6' do
          before(:each) { params.merge!(address6: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'tsig' do
          before(:each) { params.merge!(tsig: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'tsig not defined' do
          before(:each) { params.merge!(tsig: 'foobar') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'tsig with no tsig_name' do
          before(:each) { params.merge!(tsig: 'test_tsig') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'tsig_name' do
          before(:each) { params.merge!(tsig_name: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'tsig_name_notify_in' do
          before(:each) { params.merge!(tsig_name_notify_in: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'port' do
          before(:each) { params.merge!(port: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
