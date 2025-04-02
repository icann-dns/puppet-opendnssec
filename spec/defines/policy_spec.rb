# frozen_string_literal: true

require 'spec_helper'

describe 'opendnssec::policy' do
  # by default the hiera integration uses hiera data from the shared_contexts.rb file
  # but basically to mock hiera you first need to add a key/value pair
  # to the specific context in the spec/shared_contexts.rb file
  # Note: you can only use a single hiera context per describe/context block
  # rspec-puppet does not allow you to swap out hiera data on a per test block
  # include_context :hiera

  let(:title) { 'test_policy' }

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
      # :order => '10',
      # :description => :undef,
      # :resign => 'PT2H',
      # :refresh => 'P6D',
      # :validity_default => 'P21D',
      # :validity_denial => 'P21D',
      # :jitter => 'PT12H',
      # :inception_offset => 'PT3600S',
      # :denial_policy => 'NSEC3',
      # :denial_optout => true,
      # :denial_resalt => 'P100D',
      # :denial_algorithm => 'SHA1',
      # :denial_iterations => '5',
      # :denial_salt_length => '8',
      # :key_ttl => 'PT3600S',
      # :key_retire_safty => 'PT3600S',
      # :key_publish_safty => 'PT3600S',
      # :key_share_keys => false,
      # :key_purge => 'P14D',
      # :ksk_algorithm => 'RSASHA1-NSEC3-SHA1',
      # :ksk_algorithm_length => '2048',
      # :ksk_lifetime => 'P365D',
      # :ksk_repository => :undef,
      # :ksk_standby => '0',
      # :ksk_manual_rollover => true,
      # :zsk_algorithm => 'RSASHA1-NSEC3-SHA1',
      # :zsk_algorithm_length => '1024',
      # :zsk_lifetime => 'P90D',
      # :zsk_repository => :undef,
      # :zsk_standby => '0',
      # :zsk_manual_rollover => false,
      # :zone_propagation_delay => 'PT43200S',
      # :zone_soa_ttl => 'PT3600S',
      # :zone_soa_minimum => 'PT3600S',
      # :zone_soa_serial => 'unixtime',
      # :parent_propagation_delay => 'PT9999S',
      # :parent_ds_ttl => 'PT3600S',
      # :parent_soa_ttl => 'PT172800S',
      # :parent_soa_minimum => 'PT10800S',

    }
  end
  # add these two lines in a single test block to enable puppet and hiera debug mode
  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  let(:pre_condition) { 'class {\'::opendnssec\': }' }

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_opendnssec__policy('test_policy') }

        it do
          is_expected.to contain_concat__fragment('policy_test_policy').with(
            target: '/etc/opendnssec/kasp.xml',
            order: '10'
          ).with_content(
            %r{<Policy name="test_policy">}
          ).with_content(
            %r{<Description>test_policy\s-\sDeny:NSEC3;\sKSK:RSASHA1-NSEC3-SHA1;\sZSK:RSASHA1-NSEC3-SHA1</Description>}
          ).with_content(
            %r{<Signatures>
            \s+<Resign>PT2H</Resign>
            \s+<Refresh>P6D</Refresh>
            \s+<Validity>
            \s+<Default>P21D</Default>
            \s+<Denial>P21D</Denial>
            \s+</Validity>
            \s+<Jitter>PT12H</Jitter>
            \s+<InceptionOffset>PT3600S</InceptionOffset>
            \s+</Signatures>
            }x
          ).with_content(
            %r{<Denial>
            \s+<NSEC3>
            \s+<!--\s<TTL>PT0S</TTL>\s-->
            \s+<Resalt>P100D</Resalt>
            \s+<Hash>
            \s+<Algorithm>1</Algorithm>
            \s+<Iterations>0</Iterations>
            \s+<Salt\slength="0"/>
            \s+</Hash>
            \s+</NSEC3>
            }x
          ).with_content(
            %r{<!--\sParameters\sfor\sboth\sKSK\sand\sZSK\s-->
            \s+<TTL>PT3600S</TTL>
            \s+<RetireSafety>PT3600S</RetireSafety>
            \s+<PublishSafety>PT3600S</PublishSafety>
            \s+<!--\s<ShareKeys/>\s-->
            \s+<Purge>P14D</Purge>
            }x
          ).with_content(
            %r{<KSK>
            \s+<!--\sKSK\sAlgo\sRSASHA1-NSEC3-SHA1\s\(7\)\s-->
            \s+<Algorithm\slength="2048">7</Algorithm>
            \s+<Lifetime>P365D</Lifetime>
            \s+<Repository>SoftHSM</Repository>
            \s+<Standby>0</Standby>
            \s+<ManualRollover/>
            \s+</KSK>
            }x
          ).with_content(
            %r{<ZSK>
            \s+<Algorithm\slength="1024">7</Algorithm>
            \s+<Lifetime>P90D</Lifetime>
            \s+<Repository>SoftHSM</Repository>
            \s+<Standby>0</Standby>
            \s+</ZSK>
            }x
          ).with_content(
            %r{<Zone>
            \s+<PropagationDelay>PT43200S</PropagationDelay>
            \s+<SOA>
            \s+<TTL>PT3600S</TTL>
            \s+<Minimum>PT3600S</Minimum>
            \s+<Serial>keep</Serial>
            \s+</SOA>
            \s+</Zone>
            }x
          ).with_content(
            %r{<Parent>
            \s+<PropagationDelay>PT9999S</PropagationDelay>
            \s+<DS>
            \s+<TTL>PT3600S</TTL>
            \s+</DS>
            \s+<SOA>
            \s+<TTL>PT172800S</TTL>
            \s+<Minimum>PT10800S</Minimum>
            \s+</SOA>
            \s+</Parent>
            }x
          )
        end
      end

      describe 'Change Defaults' do
        context 'order' do
          before { params.merge!(order: '15') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_order('15')
          end
        end

        context 'description' do
          before { params.merge!(description: 'bla') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Description>bla</Description>}
            )
          end
        end

        context 'resign' do
          before { params.merge!(resign: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Signatures>
              \s+<Resign>P1D</Resign>
              \s+<Refresh>P6D</Refresh>
              \s+<Validity>
              \s+<Default>P21D</Default>
              \s+<Denial>P21D</Denial>
              \s+</Validity>
              \s+<Jitter>PT12H</Jitter>
              \s+<InceptionOffset>PT3600S</InceptionOffset>
              \s+</Signatures>
              }x
            )
          end
        end

        context 'refresh' do
          before { params.merge!(refresh: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Signatures>
              \s+<Resign>PT2H</Resign>
              \s+<Refresh>P1D</Refresh>
              \s+<Validity>
              \s+<Default>P21D</Default>
              \s+<Denial>P21D</Denial>
              \s+</Validity>
              \s+<Jitter>PT12H</Jitter>
              \s+<InceptionOffset>PT3600S</InceptionOffset>
              \s+</Signatures>
              }x
            )
          end
        end

        context 'validity_default' do
          before { params.merge!(validity_default: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Signatures>
              \s+<Resign>PT2H</Resign>
              \s+<Refresh>P6D</Refresh>
              \s+<Validity>
              \s+<Default>P1D</Default>
              \s+<Denial>P21D</Denial>
              \s+</Validity>
              \s+<Jitter>PT12H</Jitter>
              \s+<InceptionOffset>PT3600S</InceptionOffset>
              \s+</Signatures>
              }x
            )
          end
        end

        context 'validity_denial' do
          before { params.merge!(validity_denial: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Signatures>
              \s+<Resign>PT2H</Resign>
              \s+<Refresh>P6D</Refresh>
              \s+<Validity>
              \s+<Default>P21D</Default>
              \s+<Denial>P1D</Denial>
              \s+</Validity>
              \s+<Jitter>PT12H</Jitter>
              \s+<InceptionOffset>PT3600S</InceptionOffset>
              \s+</Signatures>
              }x
            )
          end
        end

        context 'jitter' do
          before { params.merge!(jitter: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Signatures>
              \s+<Resign>PT2H</Resign>
              \s+<Refresh>P6D</Refresh>
              \s+<Validity>
              \s+<Default>P21D</Default>
              \s+<Denial>P21D</Denial>
              \s+</Validity>
              \s+<Jitter>P1D</Jitter>
              \s+<InceptionOffset>PT3600S</InceptionOffset>
              \s+</Signatures>
              }x
            )
          end
        end

        context 'inception_offset' do
          before { params.merge!(inception_offset: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Signatures>
              \s+<Resign>PT2H</Resign>
              \s+<Refresh>P6D</Refresh>
              \s+<Validity>
              \s+<Default>P21D</Default>
              \s+<Denial>P21D</Denial>
              \s+</Validity>
              \s+<Jitter>PT12H</Jitter>
              \s+<InceptionOffset>P1D</InceptionOffset>
              \s+</Signatures>
              }x
            )
          end
        end

        context 'denial_policy' do
          before { params.merge!(denial_policy: 'NSEC') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<NSEC/>}
            ).without_content(
              %r{<NSEC3>.+</NSEC3>}
            )
          end
        end

        context 'denial_optout' do
          before { params.merge!(denial_optout: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Denial>
              \s+<NSEC3>
              \s+<!--\s<TTL>PT0S</TTL>\s-->
              \s+<OptOut/>
              \s+<Resalt>P100D</Resalt>
              \s+<Hash>
              \s+<Algorithm>1</Algorithm>
              \s+<Iterations>0</Iterations>
              \s+<Salt\slength="0"/>
              \s+</Hash>
              \s+</NSEC3>
              }x
            )
          end
        end

        context 'denial_resalt' do
          before { params.merge!(denial_resalt: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Denial>
              \s+<NSEC3>
              \s+<!--\s<TTL>PT0S</TTL>\s-->
              \s+<Resalt>P1D</Resalt>
              \s+<Hash>
              \s+<Algorithm>1</Algorithm>
              \s+<Iterations>0</Iterations>
              \s+<Salt\slength="0"/>
              \s+</Hash>
              \s+</NSEC3>
              }x
            )
          end
        end

        context 'denial_iterations' do
          before { params.merge!(denial_iterations: 1) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Denial>
              \s+<NSEC3>
              \s+<!--\s<TTL>PT0S</TTL>\s-->
              \s+<Resalt>P100D</Resalt>
              \s+<Hash>
              \s+<Algorithm>1</Algorithm>
              \s+<Iterations>1</Iterations>
              \s+<Salt\slength="0"/>
              \s+</Hash>
              \s+</NSEC3>
              }x
            )
          end
        end

        context 'denial_salt_length' do
          before { params.merge!(denial_salt_length: 1) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Denial>
              \s+<NSEC3>
              \s+<!--\s<TTL>PT0S</TTL>\s-->
              \s+<Resalt>P100D</Resalt>
              \s+<Hash>
              \s+<Algorithm>1</Algorithm>
              \s+<Iterations>0</Iterations>
              \s+<Salt\slength="1"/>
              \s+</Hash>
              \s+</NSEC3>
              }x
            )
          end
        end

        context 'key_ttl' do
          before { params.merge!(key_ttl: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<!--\sParameters\sfor\sboth\sKSK\sand\sZSK\s-->
              \s+<TTL>P1D</TTL>
              \s+<RetireSafety>PT3600S</RetireSafety>
              \s+<PublishSafety>PT3600S</PublishSafety>
              \s+<!--\s<ShareKeys/>\s-->
              \s+<Purge>P14D</Purge>
              }x
            )
          end
        end

        context 'key_retire_safty' do
          before { params.merge!(key_retire_safty: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<!--\sParameters\sfor\sboth\sKSK\sand\sZSK\s-->
              \s+<TTL>PT3600S</TTL>
              \s+<RetireSafety>P1D</RetireSafety>
              \s+<PublishSafety>PT3600S</PublishSafety>
              \s+<!--\s<ShareKeys/>\s-->
              \s+<Purge>P14D</Purge>
              }x
            )
          end
        end

        context 'key_publish_safty' do
          before { params.merge!(key_publish_safty: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<!--\sParameters\sfor\sboth\sKSK\sand\sZSK\s-->
              \s+<TTL>PT3600S</TTL>
              \s+<RetireSafety>PT3600S</RetireSafety>
              \s+<PublishSafety>P1D</PublishSafety>
              \s+<!--\s<ShareKeys/>\s-->
              \s+<Purge>P14D</Purge>
              }x
            )
          end
        end

        context 'key_purge' do
          before { params.merge!(key_purge: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<!--\sParameters\sfor\sboth\sKSK\sand\sZSK\s-->
              \s+<TTL>PT3600S</TTL>
              \s+<RetireSafety>PT3600S</RetireSafety>
              \s+<PublishSafety>PT3600S</PublishSafety>
              \s+<!--\s<ShareKeys/>\s-->
              \s+<Purge>P1D</Purge>
              }x
            )
          end
        end

        context 'ksk_algorithm' do
          before { params.merge!(ksk_algorithm: 'RSASHA1') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<KSK>
              \s+<!--\sKSK\sAlgo\sRSASHA1\s\(5\)\s-->
              \s+<Algorithm\slength="2048">5</Algorithm>
              \s+<Lifetime>P365D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+<ManualRollover/>
              \s+</KSK>
              }x
            )
          end
        end

        context 'ksk_algorithm_ecdsa' do
          before { params.merge!(ksk_algorithm: 'ECDSAP256SHA256') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<KSK>
              \s+<!--\sKSK\sAlgo\sECDSAP256SHA256\s\(13\)\s-->
              \s+<Algorithm\slength="2048">13</Algorithm>
              \s+<Lifetime>P365D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+<ManualRollover/>
              \s+</KSK>
              }x
            )
          end
        end

        context 'ksk_algorithm_length' do
          before { params.merge!(ksk_algorithm_length: 1024) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<KSK>
              \s+<!--\sKSK\sAlgo\sRSASHA1-NSEC3-SHA1\s\(7\)\s-->
              \s+<Algorithm\slength="1024">7</Algorithm>
              \s+<Lifetime>P365D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+<ManualRollover/>
              \s+</KSK>
              }x
            )
          end
        end

        context 'ksk_lifetime' do
          before { params.merge!(ksk_lifetime: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<KSK>
              \s+<!--\sKSK\sAlgo\sRSASHA1-NSEC3-SHA1\s\(7\)\s-->
              \s+<Algorithm\slength="2048">7</Algorithm>
              \s+<Lifetime>P1D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+<ManualRollover/>
              \s+</KSK>
              }x
            )
          end
        end

        context 'ksk_standby' do
          before { params.merge!(ksk_standby: 1) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<KSK>
              \s+<!--\sKSK\sAlgo\sRSASHA1-NSEC3-SHA1\s\(7\)\s-->
              \s+<Algorithm\slength="2048">7</Algorithm>
              \s+<Lifetime>P365D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>1</Standby>
              \s+<ManualRollover/>
              \s+</KSK>
              }x
            )
          end
        end

        context 'ksk_manual_rollover' do
          before { params.merge!(ksk_manual_rollover: false) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<KSK>
              \s+<!--\sKSK\sAlgo\sRSASHA1-NSEC3-SHA1\s\(7\)\s-->
              \s+<Algorithm\slength="2048">7</Algorithm>
              \s+<Lifetime>P365D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+</KSK>
              }x
            )
          end
        end

        context 'zsk_algorithm' do
          before { params.merge!(zsk_algorithm: 'RSASHA1') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<ZSK>
              \s+<Algorithm\slength="1024">5</Algorithm>
              \s+<Lifetime>P90D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+</ZSK>
              }x
            )
          end
        end

        context 'zsk_algorithm_ecdsa' do
          before { params.merge!(zsk_algorithm: 'ECDSAP256SHA256') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<ZSK>
              \s+<Algorithm\slength="1024">13</Algorithm>
              \s+<Lifetime>P90D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+</ZSK>
              }x
            )
          end
        end

        context 'zsk_algorithm_length' do
          before { params.merge!(zsk_algorithm_length: 2048) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<ZSK>
              \s+<Algorithm\slength="2048">7</Algorithm>
              \s+<Lifetime>P90D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+</ZSK>
              }x
            )
          end
        end

        context 'zsk_lifetime' do
          before { params.merge!(zsk_lifetime: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<ZSK>
              \s+<Algorithm\slength="1024">7</Algorithm>
              \s+<Lifetime>P1D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+</ZSK>
              }x
            )
          end
        end

        context 'zsk_standby' do
          before { params.merge!(zsk_standby: 1) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<ZSK>
              \s+<Algorithm\slength="1024">7</Algorithm>
              \s+<Lifetime>P90D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>1</Standby>
              \s+</ZSK>
              }x
            )
          end
        end

        context 'zsk_manual_rollover' do
          before { params.merge!(zsk_manual_rollover: true) }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<ZSK>
              \s+<Algorithm\slength="1024">7</Algorithm>
              \s+<Lifetime>P90D</Lifetime>
              \s+<Repository>SoftHSM</Repository>
              \s+<Standby>0</Standby>
              \s+<ManualRollover/>
              \s+</ZSK>
              }x
            )
          end
        end

        context 'zone_propagation_delay' do
          before { params.merge!(zone_propagation_delay: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Zone>
              \s+<PropagationDelay>P1D</PropagationDelay>
              \s+<SOA>
              \s+<TTL>PT3600S</TTL>
              \s+<Minimum>PT3600S</Minimum>
              \s+<Serial>keep</Serial>
              \s+</SOA>
              \s+</Zone>
              }x
            )
          end
        end

        context 'zone_soa_ttl' do
          before { params.merge!(zone_soa_ttl: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Zone>
              \s+<PropagationDelay>PT43200S</PropagationDelay>
              \s+<SOA>
              \s+<TTL>P1D</TTL>
              \s+<Minimum>PT3600S</Minimum>
              \s+<Serial>keep</Serial>
              \s+</SOA>
              \s+</Zone>
              }x
            )
          end
        end

        context 'zone_soa_minimum' do
          before { params.merge!(zone_soa_minimum: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Zone>
              \s+<PropagationDelay>PT43200S</PropagationDelay>
              \s+<SOA>
              \s+<TTL>PT3600S</TTL>
              \s+<Minimum>P1D</Minimum>
              \s+<Serial>keep</Serial>
              \s+</SOA>
              \s+</Zone>
              }x
            )
          end
        end

        context 'zone_soa_serial' do
          before { params.merge!(zone_soa_serial: 'counter') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Zone>
              \s+<PropagationDelay>PT43200S</PropagationDelay>
              \s+<SOA>
              \s+<TTL>PT3600S</TTL>
              \s+<Minimum>PT3600S</Minimum>
              \s+<Serial>counter</Serial>
              \s+</SOA>
              \s+</Zone>
              }x
            )
          end
        end

        context 'parent_propagation_delay' do
          before { params.merge!(parent_propagation_delay: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Parent>
              \s+<PropagationDelay>P1D</PropagationDelay>
              \s+<DS>
              \s+<TTL>PT3600S</TTL>
              \s+</DS>
              \s+<SOA>
              \s+<TTL>PT172800S</TTL>
              \s+<Minimum>PT10800S</Minimum>
              \s+</SOA>
              \s+</Parent>
              }x
            )
          end
        end

        context 'parent_ds_ttl' do
          before { params.merge!(parent_ds_ttl: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Parent>
              \s+<PropagationDelay>PT9999S</PropagationDelay>
              \s+<DS>
              \s+<TTL>P1D</TTL>
              \s+</DS>
              \s+<SOA>
              \s+<TTL>PT172800S</TTL>
              \s+<Minimum>PT10800S</Minimum>
              \s+</SOA>
              \s+</Parent>
              }x
            )
          end
        end

        context 'parent_soa_ttl' do
          before { params.merge!(parent_soa_ttl: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Parent>
              \s+<PropagationDelay>PT9999S</PropagationDelay>
              \s+<DS>
              \s+<TTL>PT3600S</TTL>
              \s+</DS>
              \s+<SOA>
              \s+<TTL>P1D</TTL>
              \s+<Minimum>PT10800S</Minimum>
              \s+</SOA>
              \s+</Parent>
              }x
            )
          end
        end

        context 'parent_soa_minimum' do
          before { params.merge!(parent_soa_minimum: 'P1D') }

          it { is_expected.to compile }

          it do
            is_expected.to contain_concat__fragment(
              'policy_test_policy'
            ).with_content(
              %r{<Parent>
              \s+<PropagationDelay>PT9999S</PropagationDelay>
              \s+<DS>
              \s+<TTL>PT3600S</TTL>
              \s+</DS>
              \s+<SOA>
              \s+<TTL>PT172800S</TTL>
              \s+<Minimum>P1D</Minimum>
              \s+</SOA>
              \s+</Parent>
              }x
            )
          end
        end
      end

      describe 'check bad type' do
        context 'order' do
          before { params.merge!(order: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'description' do
          before { params.merge!(description: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'resign' do
          before { params.merge!(resign: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'refresh' do
          before { params.merge!(refresh: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'validity_default' do
          before { params.merge!(validity_default: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'validity_denial' do
          before { params.merge!(validity_denial: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'jitter' do
          before { params.merge!(jitter: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'inception_offset' do
          before { params.merge!(inception_offset: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'denial_policy' do
          before { params.merge!(denial_policy: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'denial_optout' do
          before { params.merge!(denial_optout: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'denial_resalt' do
          before { params.merge!(denial_resalt: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'denial_algorithm' do
          before { params.merge!(denial_algorithm: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'denial_iterations' do
          before { params.merge!(denial_iterations: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'denial_salt_length' do
          before { params.merge!(denial_salt_length: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'key_ttl' do
          before { params.merge!(key_ttl: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'key_retire_safty' do
          before { params.merge!(key_retire_safty: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'key_publish_safty' do
          before { params.merge!(key_publish_safty: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'key_share_keys' do
          before { params.merge!(key_share_keys: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'key_purge' do
          before { params.merge!(key_purge: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_algorithm' do
          before { params.merge!(ksk_algorithm: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_algorithm_ecdsa' do
          before { params.merge!(ksk_algorithm: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_algorithm_length' do
          before { params.merge!(ksk_algorithm_length: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_lifetime' do
          before { params.merge!(ksk_lifetime: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_repository' do
          before { params.merge!(ksk_repository: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_standby' do
          before { params.merge!(ksk_standby: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'ksk_manual_rollover' do
          before { params.merge!(ksk_manual_rollover: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_algorithm' do
          before { params.merge!(zsk_algorithm: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_algorithm_ecdsa' do
          before { params.merge!(zsk_algorithm: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_algorithm_length' do
          before { params.merge!(zsk_algorithm_length: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_lifetime' do
          before { params.merge!(zsk_lifetime: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_repository' do
          before { params.merge!(zsk_repository: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_standby' do
          before { params.merge!(zsk_standby: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zsk_manual_rollover' do
          before { params.merge!(zsk_manual_rollover: 'foobar') }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zone_propagation_delay' do
          before { params.merge!(zone_propagation_delay: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zone_soa_ttl' do
          before { params.merge!(zone_soa_ttl: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zone_soa_minimum' do
          before { params.merge!(zone_soa_minimum: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'zone_soa_serial' do
          before { params.merge!(zone_soa_serial: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'parent_propagation_delay' do
          before { params.merge!(parent_propagation_delay: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'parent_ds_ttl' do
          before { params.merge!(parent_ds_ttl: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'parent_soa_ttl' do
          before { params.merge!(parent_soa_ttl: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end

        context 'parent_soa_minimum' do
          before { params.merge!(parent_soa_minimum: true) }

          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
