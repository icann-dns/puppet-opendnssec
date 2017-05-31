require 'spec_helper'

describe 'opendnssec::addns::xfer_out' do
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
      #:slaves => {},
      #:remotes => {},

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
    is_expected.to contain_concat__fragment("xfer_out_providetransfer_header_$name")
        .with({
          "target" => "$::opendnssec::addns_file",
          "content" => "      <ProvideTransfer>\n",
          "order" => "31",
          })
  end
          
  it do
    is_expected.to contain_concat__fragment("xfer_out_providetransfer_footer_$name")
        .with({
          "target" => "$::opendnssec::addns_file",
          "content" => "\n      </ProvideTransfer>\n",
          "order" => "33",
          })
  end
          
  it do
    is_expected.to contain_concat__fragment("xfer_out_notify_header_$name")
        .with({
          "target" => "$::opendnssec::addns_file",
          "content" => "      <Notify>\n",
          "order" => "34",
          })
  end
          
  it do
    is_expected.to contain_concat__fragment("xfer_out_notify_footer_$name")
        .with({
          "target" => "$::opendnssec::addns_file",
          "content" => "\n      </Notify>\n",
          "order" => "36",
          })
  end
        end
      describe 'Change Defaults' do
        context 'slaves' do
          before { params.merge!(slaves: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
        context 'remotes' do
          before { params.merge!(remotes: 'XXXchangemeXXX') }
          it { is_expected.to compile }
          # Add Check to validate change was successful
        end
      end
      describe 'check bad type' do
        context 'slaves' do
          before { params.merge!(slaves: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
        context 'remotes' do
          before { params.merge!(remotes: true) }
          it { expect { subject.call }.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
