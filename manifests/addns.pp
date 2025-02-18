# @summary Add a new addns configuration
# @param masters Array of masters to add
# @param provide_xfrs Array of masters to provide xfrs to
#
define opendnssec::addns (
  Array[String] $masters      = [],
  Array[String] $provide_xfrs = [],
) {

  include ::opendnssec
  $xsl_file           = $::opendnssec::xsl_file
  $user               = $::opendnssec::user
  $group              = $::opendnssec::group
  $manage_ods_ksmutil = $::opendnssec::manage_ods_ksmutil
  $enabled            = $::opendnssec::enabled
  $remotes            = $::opendnssec::remotes
  $remotes_dir        = $::opendnssec::remotes_dir
  $tsigs_dir          = $::opendnssec::tsigs_dir
  $xferout_enabled    = $::opendnssec::xferout_enabled
  $default_tsig_name  = $::opendnssec::default_tsig_name
  $masters.each |String $master| {
    if ! defined(Opendnssec::Remote[$master]) {
      fail("addns-${name}: Opendnssec::Remote['${master}'] doesn't exist")
    }
  }
  $provide_xfrs.each |String $provide_xfr| {
    if ! defined(Opendnssec::Remote[$provide_xfr]) {
      fail("addns-${name}: Opendnssec::Remote['${provide_xfr}'] doesn't exist")
    }
  }

  file { "/etc/opendnssec/addns-${name}.xml.tmp":
    owner   => $user,
    group   => $group,
    content => template('opendnssec/etc/opendnssec/addns.xml.erb'),
    notify  => Exec["write /etc/opendnssec/addns-${name}.xml"],
  }
  exec { "write /etc/opendnssec/addns-${name}.xml":
    command     => "/usr/bin/xsltproc --xinclude ${xsl_file} /etc/opendnssec/addns-${name}.xml.tmp | sed 's/\sxml:base[^>]*//g' > /etc/opendnssec/addns-${name}.xml",
    refreshonly => true,
  }
}
