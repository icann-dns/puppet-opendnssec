require 'spec_helper'

describe 'opendnssec::zone' do
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
      :policy => nil,
      #:order => "10",
      #:adapter_base_dir => "/var/lib/opendnssec",
      #:adapter_signer_conf => :undef,
      #:adapter_input_file => :undef,
      #:adapter_output_file => :undef,
      #:adapter_input_type => "DNS",
      #:adapter_output_type => "DNS",

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
    is_expected.to contain_concat__fragment("zone_$name")
        .with({
          "target" => "$::opendnssec::zone_file",
          "content" => [],
          "order" => "10",
          })
  end
        end
      describe 'Change Defaults' do
        context 'olicy' do
          before { params.merge!(olicy: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'order' do
          before { params.merge!(order: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'adapter_base_dir' do
          before { params.merge!(adapter_base_dir: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'adapter_signer_conf' do
          before { params.merge!(adapter_signer_conf: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'adapter_input_file' do
          before { params.merge!(adapter_input_file: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'adapter_output_file' do
          before { params.merge!(adapter_output_file: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'adapter_input_type' do
          before { params.merge!(adapter_input_type: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'adapter_output_type' do
          before { params.merge!(adapter_output_type: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
      end
      describe 'check bad type' do
        context 'olicy' do
          before { params.merge!(olicy: true) }
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
