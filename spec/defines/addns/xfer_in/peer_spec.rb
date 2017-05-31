require 'spec_helper'

describe 'opendnssec::addns::xfer_in::peer' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  #include_context :hiera

  let(:title) { 'XXreplace_meXX' }

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
      #:order => "25",
      #:port => "53",
      #:address => :undef,
      #:key => :undef,
      #:prefix => :undef,

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let (:pre_condition) { "class {'::xxxCHANGEMExxx' }" }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end
      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        
  it do
    is_expected.to contain_concat__fragment("xfer_in_peer_$name")
        .with({
          "target" => "$::opendnssec::addns_file",
          "content" => [],
          "order" => "25",
          })
  end
        end
      describe 'Change Defaults' do
        context 'order' do
          before { params.merge!(order: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'port' do
          before { params.merge!(port: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'address' do
          before { params.merge!(address: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'key' do
          before { params.merge!(key: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'prefix' do
          before { params.merge!(prefix: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
      end
      describe 'check bad type' do
        context 'order' do
          before { params.merge!(order: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'port' do
          before { params.merge!(port: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'address' do
          before { params.merge!(address: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'key' do
          before { params.merge!(key: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'prefix' do
          before { params.merge!(prefix: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
