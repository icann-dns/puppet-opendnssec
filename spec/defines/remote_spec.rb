# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::remote' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_remote' }

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
      address4: '192.0.2.1'
      # address6: :undef,
      # tsig: :undef,
      # tsig_name: :undef,
      # port: "53",

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
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }

        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
          ).with(
            ensure: 'file',
            owner: 'root',
            group: 'root'
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<RequestTransfer>
            \s+<Remote>
            \s+<Address>192.0.2.1</Address>
            \s+<Port>53</Port>
            \s+</Remote>
            \s+</RequestTransfer>
            }x
          )
        end
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_notify_in.xml'
          ).with(
            ensure: 'file',
            owner: 'root',
            group: 'root'
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<AllowNotify>
            \s+<Peer>
            \s+<Prefix>192.0.2.1</Prefix>
            \s+</Peer>
            \s+</AllowNotify>
            }x
          )
        end
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
          ).with(
            ensure: 'file',
            owner: 'root',
            group: 'root'
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<ProvideTransfer>
            \s+<Peer>
            \s+<Prefix>192.0.2.1</Prefix>
            \s+</Peer>
            \s+</ProvideTransfer>
            }x
          )
        end
        it do
          is_expected.to contain_file(
            '/etc/opendnssec/remotes/test_remote_notify_out.xml'
          ).with(
            ensure: 'file',
            owner: 'root',
            group: 'root'
          ).with_content(
            %r{
            <\?xml\sversion="1.0"\?>
            \s+<Notify>
            \s+<Remote>
            \s+<Address>192.0.2.1</Address>
            \s+<Port>53</Port>
            \s+</Remote>
            \s+</Notify>
            }x
          )
        end
      end
      describe 'Change Defaults' do
        context 'address4' do
          before { params.merge!(address4: '192.0.2.255') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.255</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.255</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.255</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.255</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x
            )
          end
        end
        context 'address6' do
          before { params.merge!(address6: '2001:DB8::1') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
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
              }x
            )
          end
        end
        context 'ipv6 only' do
          before { params.merge!(address4: :undef, address6: '2001:DB8::1') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>2001:DB8::1</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>2001:DB8::1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x
            )
          end
        end
        context 'tsig' do
          before { params.merge!(tsig: 'test_tsig', tsig_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>foobar</Key>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x
            )
          end
        end
        context 'tsig_name' do
          before { params.merge!(tsig_name: 'test_tsig') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+<Key>test_tsig</Key>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>53</Port>
              \s+</Remote>
              \s+</Notify>
              }x
            )
          end
        end
        context 'port' do
          before { params.merge!(port: 5353) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<RequestTransfer>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>5353</Port>
              \s+</Remote>
              \s+</RequestTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<AllowNotify>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</AllowNotify>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<ProvideTransfer>
              \s+<Peer>
              \s+<Prefix>192.0.2.1</Prefix>
              \s+</Peer>
              \s+</ProvideTransfer>
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\?>
              \s+<Notify>
              \s+<Remote>
              \s+<Address>192.0.2.1</Address>
              \s+<Port>5353</Port>
              \s+</Remote>
              \s+</Notify>
              }x
            )
          end
        end
        context 'All params' do
          before do
            params.merge!(
              address6: '2001:DB8::1',
              port: 5353,
              tsig_name: 'test_tsig'
            )
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_requesttransfer.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_in.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_providetransfer.xml'
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
              }x
            )
          end
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/remotes/test_remote_notify_out.xml'
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
              }x
            )
          end
        end
      end
      describe 'check bad type' do
        context 'no address' do
          before { params.merge!(address4: nil) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'address4' do
          before { params.merge!(address4: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'address6' do
          before { params.merge!(address6: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig' do
          before { params.merge!(tsig: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig not defined' do
          before { params.merge!(tsig: 'foobar') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig with no tsig_name' do
          before { params.merge!(tsig: 'test_tsig') }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig_name' do
          before { params.merge!(tsig_name: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'port' do
          before { params.merge!(port: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
