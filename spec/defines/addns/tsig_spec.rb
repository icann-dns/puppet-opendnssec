# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::addns::tsig' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_tsig' }

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
      secret: 'AAAA',
      #:order => "15",
      #:tsig_name => :undef,
      #:algorithm => "hmac-md5",

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let(:pre_condition) { "class {'::opendnssec': }" }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_concat__fragment('tsig_test_tsig').with(
            'target' => '/etc/opendnssec/addns.xml',
            'order' => '15'
          ).with_content(
            %r{<TSIG>
            \s+<Name>test_tsig</Name>
            \s+<Algorithm>hmac-md5</Algorithm>
            \s+<Secret>AAAA</Secret>
            \s+</TSIG>
            }x
          )
        end
      end
      describe 'Change Defaults' do
        context 'order' do
          before { params.merge!(order: '22') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment(
              'tsig_test_tsig'
            ).with_order('22')
          end
        end
        context 'tsig_name' do
          before { params.merge!(tsig_name: 'foobar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('tsig_test_tsig').with(
              'target' => '/etc/opendnssec/addns.xml',
            ).with_content(
              %r{<TSIG>
              \s+<Name>foobar</Name>
              \s+<Algorithm>hmac-md5</Algorithm>
              \s+<Secret>AAAA</Secret>
              \s+</TSIG>
              }x
            )
          end
        end
        context 'algorithm' do
          before { params.merge!(algorithm: 'hmac-sha1') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('tsig_test_tsig').with(
              'target' => '/etc/opendnssec/addns.xml',
            ).with_content(
              %r{<TSIG>
              \s+<Name>test_tsig</Name>
              \s+<Algorithm>hmac-sha1</Algorithm>
              \s+<Secret>AAAA</Secret>
              \s+</TSIG>
              }x
            )
          end
        end
        context 'secret' do
          before { params.merge!(secret: 'BBBB') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_concat__fragment('tsig_test_tsig').with(
              'target' => '/etc/opendnssec/addns.xml',
            ).with_content(
              %r{<TSIG>
              \s+<Name>test_tsig</Name>
              \s+<Algorithm>hmac-md5</Algorithm>
              \s+<Secret>BBBB</Secret>
              \s+</TSIG>
              }x
            )
          end
        end
      end
      describe 'check bad type' do
        context 'order' do
          before { params.merge!(order: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'tsig_name' do
          before { params.merge!(tsig_name: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'algorithm' do
          before { params.merge!(algorithm: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'secret' do
          before { params.merge!(secret: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
