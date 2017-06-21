[![Build Status](https://travis-ci.org/icann-dns/puppet-opendnssec.svg?branch=master)](https://travis-ci.org/icann-dns/puppet-opendnssec)
[![Puppet Forge](https://img.shields.io/puppetforge/v/icann/opendnssec.svg?maxAge=2592000)](https://forge.puppet.com/icann/opendnssec)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/icann/opendnssec.svg?maxAge=2592000)](https://forge.puppet.com/icann/opendnssec)
# opendnssec

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with opendnssec](#setup)
    * [What opendnssec affects](#what-opendnssec-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with opendnssec](#beginning-with-opendnssec)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Manage client and server](#manage-client-and-server)
    * [Ansible client](#opendnssec-client)
    * [Ansible Server](#opendnssec-server)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
    * [Classes](#classes)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module installs is used to manage opendnssec, specificly we wanted a way to secure the opendnssec menu entry which i did not find at the time.  In future we will look to migrate to [herculesteam-augeasproviders_opendnssec](https://forge.puppet.com/herculesteam/augeasproviders_opendnssec)

## Setup

### What opendnssec affects

* Manages the opendnssec menu item and superusers

### Setup Requirements

* puppetlabs-stdlib 4.12.0

### Beginning with opendnssec

just add the opendnssec class.

```puppet
class {'::opendnssec' }
```

## Usage

### Add an user and password and protectect edit functions

```puppet
class {'::opendnssec' 
  user => 'test',
  password => opendnssec.pbkdf2.sha512.10000.$SOMHEHASH,
}
```

of with hiera

```yaml
opendnssec::user: test
grup::password: opendnssec.pbkdf2.sha512.10000.$SOMHEHASH
```

## Reference

### Classes

#### Public Classes

* [`opendnssec`](#class-opendnssec)

#### Class: `opendnssec`

Main class, includes all other classes

##### Parameters 


## Limitations

This module is tested on Ubuntu 12.04, and 14.04
