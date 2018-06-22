#== Class: opendnssec::params
#
class opendnssec::params {
  case $::operatingsystem {
    'RedHat' : {
      $packages = ['opendnssec', 'libxslt']
      $services = ['ods-enforcerd', 'ods-signerd']
      $base_dir = '/var/opendnssec'
      $repository_module = '/usr/lib64/pkcs11/libsofthsm2.so'
      $sqlite_packages = []
      $mysql_packages = []
      $ksmutil_path = '/bin/ods-ksmutil'
    }
    'ubuntu': {
      case $::lsbdistcodename {
        'trusty': {
          $packages = ['opendnssec', 'xsltproc']
          $services = ['opendnssec-enforcer', 'opendnssec-signer']
          $base_dir = '/var/lib/opendnssec'
          $repository_module = '/usr/lib/softhsm/libsofthsm.so'
          $sqlite_packages = ['opendnssec-enforcer-sqlite']
          $mysql_packages = ['opendnssec-enforcer-mysql']
          $ksmutil_path = '/usr/bin/ods-ksmutil'
        }
        default: {
          $packages = ['opendnssec', 'xsltproc']
          $services = ['opendnssec-enforcer', 'opendnssec-signer']
          $base_dir = '/var/lib/opendnssec'
          $repository_module = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so'
          $sqlite_packages = ['opendnssec-enforcer-sqlite']
          $mysql_packages = ['opendnssec-enforcer-mysql']
          $ksmutil_path = '/usr/bin/ods-ksmutil'
        }
      }
    }
    default: {
      $packages = ['opendnssec', 'xsltproc']
      $services = ['opendnssec-enforcer', 'opendnssec-signer']
      $base_dir = '/var/lib/opendnssec'
      $repository_module = '/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so'
      $sqlite_packages = ['opendnssec-enforcer-sqlite']
      $mysql_packages = ['opendnssec-enforcer-mysql']
      $ksmutil_path = '/usr/bin/ods-ksmutil'
    }
  }

}
