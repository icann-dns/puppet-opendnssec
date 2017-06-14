#== Class: softhsm
#
class opendnssec::params {
  case $::lsbdistcodename {
    'trusty': {
      $repository_module = '/usr/lib/softhsm/libsofthsm.so'
    }
    default: {
      $repository_module = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so'
    }
  }
}
