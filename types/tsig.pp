type Opendnssec::Tsig = Struct[{
  data => Tea::Base64,
  algo => Opendnssec::Tsigalgo,
  key_name => Optional[String],
}]
