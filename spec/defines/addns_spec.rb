# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::addns' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_addns' }

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
      # masters: ['master'],
      # provide_xfrs: [],

    }
  end
  let(:pre_condition) do
    <<-EOF
    class { '::opendnssec':
      policies => {'test_policy' => {} },
      remotes  => {
        'master' => { 'address4' => '192.0.2.1' },
        'provide_xfr' => { 'address4' => '192.0.2.2' },
      },
    }
    EOF
  end

  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_opendnssec__addns('test_addns') }
        it do
          is_expected.to contain_file('/etc/opendnssec/addns-test_addns.xml.tmp').with(
            owner: 'root',
          ).with_content(
            %r{
			<\?xml\sversion="1.0"\sencoding="UTF-8"\?>
			\s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
            \s+<Adapter\sxmlns:xi="http://www.w3.org/2001/XInclude">
			\s+<DNS>
			\s+<Inbound>
			\s+</Inbound>
			\s+<Outbound>
			\s+</Outbound>
			\s+</DNS>
			\s+</Adapter>
            }x,
          )
        end
      end
      describe 'Change Defaults' do
        context 'masters' do
          before(:each) { params.merge!(masters: ['master']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/etc/opendnssec/addns-test_addns.xml.tmp').with(
              owner: 'root',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter\sxmlns:xi="http://www.w3.org/2001/XInclude">
              \s+<DNS>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"
              \s+xpointer="xpointer\(//RequestTransfer/Remote\)"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"
              \s+xpointer="xpointer\(//AllowNotify/Peer\)"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x,
            )
          end
        end
        context 'provide_xfrs' do
          before(:each) { params.merge!(provide_xfrs: ['provide_xfr']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter\sxmlns:xi="http://www.w3.org/2001/XInclude">
              \s+<DNS>
              \s+<Inbound>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"
              \s+xpointer="xpointer\(//ProvideTransfer/Peer\)"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"
              \s+xpointer="xpointer\(//Notify/Remote\)"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x,
            )
          end
        end
        context 'provide_xfrs and master' do
          before(:each) { params.merge!(provide_xfrs: ['provide_xfr'], masters: ['master']) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter\sxmlns:xi="http://www.w3.org/2001/XInclude">
              \s+<DNS>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"
              \s+xpointer="xpointer\(//RequestTransfer/Remote\)"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"
              \s+xpointer="xpointer\(//AllowNotify/Peer\)"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"
              \s+xpointer="xpointer\(//ProvideTransfer/Peer\)"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"
              \s+xpointer="xpointer\(//Notify/Remote\)"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x,
            )
          end
        end
        context 'opendnssec::user' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              user => 'foobar',
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_owner('foobar')
          end
        end
        context 'opendnssec::group' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              group => 'foobar',
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_group('foobar')
          end
        end
        context 'opendnssec::manage_ods_ksmutil' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              manage_ods_ksmutil => false,
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_addns.xml.tmp',
            )
          end
        end
        context 'opendnssec::enabled' do
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              enabled => false,
              policies => {'test_policy' => {} },
              remotes  => {
                'master' => { 'address4' => '192.0.2.1' },
                'provide_xfr' => { 'address4' => '192.0.2.2' },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.not_to contain_exec(
              'Forcing ods-ksmutil to update after modifying addns-test_addns.xml.tmp',
            )
          end
        end
        context 'opendnssec::remotes disable notifies' do
          before(:each) { params.merge!(provide_xfrs: ['slave', 'dummy']) }
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              tsigs => {
                'tsig_slave' => { 'data' => 'AAAA', 'algo' => 'hmac-sha1' },
                'tsig_dummy' => { 'data' => 'BBBB', 'algo' => 'hmac-sha1' },
              },
              remotes => {
                slave => {
                  'address4' => '192.168.0.1',
                  'tsig_name' => 'tsig_slave',
                },
                dummy => {
                  'address4' => '192.168.0.20',
                  'tsig_name' => 'tsig_dummy',
                  'send_notifies' => false,
                }
              }
            }
            EOF
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_content(
              %r{
                \s+<Notify>
                \s+<xi:include\shref="/etc/opendnssec/remotes/slave_notify_out.xml"
                \s+xpointer="xpointer\(//Notify/Remote\)"\s/>
                \s+</Notify>
              }x
            )
          end
        end
        context 'opendnssec::remotes Tsig name' do
          before(:each) { params.merge!(provide_xfrs: ['provide_xfr'], masters: ['master']) }
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              policies => {'test_policy' => {} },
              tsigs => {
                'test_tsig_master' => { 'data' => 'AAAA', 'algo' => 'hmac-sha1' },
                'test_tsig_provide_xfr' => { 'data' => 'BBBB','algo' => 'hmac-md5' },
              },
              remotes  => {
                'master' => {
                  'address4' => '192.0.2.1',
                  'tsig_name' => 'test_tsig_master',
                },
                'provide_xfr' => {
                  'address4' => '192.0.2.2',
                  'tsig_name' => 'test_tsig_provide_xfr',
                },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter\sxmlns:xi="http://www.w3.org/2001/XInclude">
              \s+<DNS>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_master.xml"
              \s+xpointer="xpointer\(//TSIG\)"\s/>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_provide_xfr.xml"
              \s+xpointer="xpointer\(//TSIG\)"\s/>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"
              \s+xpointer="xpointer\(//RequestTransfer/Remote\)"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"
              \s+xpointer="xpointer\(//AllowNotify/Peer\)"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"
              \s+xpointer="xpointer\(//ProvideTransfer/Peer\)"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"
              \s+xpointer="xpointer\(//Notify/Remote\)"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x,
            )
          end
        end
        context 'opendnssec::remotes default_tsig_name' do
          before(:each) { params.merge!(provide_xfrs: ['provide_xfr'], masters: ['master']) }
          let(:pre_condition) do
            <<-EOF
            class { '::opendnssec':
              policies => {'test_policy' => {} },
              default_tsig_name => 'test_tsig_default',
              tsigs => {
                'test_tsig_default' => { 'data' => 'AAAA', 'algo' => 'hmac-sha1' },
                'test_tsig_provide_xfr' => { 'data' => 'BBBB','algo' => 'hmac-md5' },
              },
              remotes  => {
                'master' => {
                  'address4' => '192.0.2.1',
                },
                'provide_xfr' => {
                  'address4' => '192.0.2.2',
                  'tsig_name' => 'test_tsig_provide_xfr',
                },
              },
            }
            EOF
          end

          it { is_expected.to compile }
          it do
            is_expected.to contain_file(
              '/etc/opendnssec/addns-test_addns.xml.tmp',
            ).with_content(
              %r{
              <\?xml\sversion="1.0"\sencoding="UTF-8"\?>
              \s+<!--\sFile\smanaged\sby\spuppet\sDO\sNOT\sEDIT\s-->
              \s+<Adapter\sxmlns:xi="http://www.w3.org/2001/XInclude">
              \s+<DNS>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_default.xml"
              \s+xpointer="xpointer\(//TSIG\)"\s/>
              \s+<xi:include\shref="/etc/opendnssec/tsigs/test_tsig_provide_xfr.xml"
              \s+xpointer="xpointer\(//TSIG\)"\s/>
              \s+<Inbound>
              \s+<RequestTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_requesttransfer.xml"
              \s+xpointer="xpointer\(//RequestTransfer/Remote\)"\s/>
              \s+</RequestTransfer>
              \s+<AllowNotify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/master_notify_in.xml"
              \s+xpointer="xpointer\(//AllowNotify/Peer\)"\s/>
              \s+</AllowNotify>
              \s+</Inbound>
              \s+<Outbound>
              \s+<ProvideTransfer>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_providetransfer.xml"
              \s+xpointer="xpointer\(//ProvideTransfer/Peer\)"\s/>
              \s+</ProvideTransfer>
              \s+<Notify>
              \s+<xi:include\shref="/etc/opendnssec/remotes/provide_xfr_notify_out.xml"
              \s+xpointer="xpointer\(//Notify/Remote\)"\s/>
              \s+</Notify>
              \s+</Outbound>
              \s+</DNS>
              \s+</Adapter>
              }x,
            )
          end
        end
      end
      describe 'check bad type' do
        context 'masters' do
          before(:each) { params.merge!(masters: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'provide_xfrs' do
          before(:each) { params.merge!(provide_xfrs: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
