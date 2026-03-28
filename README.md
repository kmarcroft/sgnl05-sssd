# sssd

[![CI](https://github.com/kmarcroft/puppet-sssd/actions/workflows/ci.yml/badge.svg)](https://github.com/kmarcroft/puppet-sssd/actions/workflows/ci.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/marckri/sssd.svg)](https://forge.puppet.com/marckri/sssd)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/marckri/sssd.svg)](https://forge.puppet.com/marckri/sssd)

#### Table of Contents

1. [Overview](#overview)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Limitations - OS compatibility, etc.](#limitations)
4. [Credits](#credits)

## Overview

This module installs and configures SSSD (System Security Services Daemon)

[SSSD][0] is used to provide access to identity and authentication remote resource through a common framework that can provide caching and offline support to the system.

See [REFERENCE.md](REFERENCE.md) for detailed parameter documentation.

## Usage

Example configuration:

```puppet
class { 'sssd':
  config => {
    'sssd' => {
      'domains'             => 'ad.example.com',
      'config_file_version' => 2,
      'services'            => ['nss', 'pam'],
    },
    'domain/ad.example.com' => {
      'ad_domain'                      => 'ad.example.com',
      'ad_server'                      => ['server01.ad.example.com', 'server02.ad.example.com'],
      'krb5_realm'                     => 'AD.EXAMPLE.COM',
      'realmd_tags'                    => 'joined-with-samba',
      'cache_credentials'              => true,
      'id_provider'                    => 'ad',
      'krb5_store_password_if_offline' => true,
      'default_shell'                  => '/bin/bash',
      'ldap_id_mapping'                => false,
      'use_fully_qualified_names'      => false,
      'fallback_homedir'               => '/home/%d/%u',
      'access_provider'                => 'simple',
      'simple_allow_groups'            => ['admins', 'users'],
    }
  }
}
```

...or the same config in Hiera:

```yaml
sssd::config:
  'sssd':
    'domains': 'ad.example.com'
    'config_file_version': 2
    'services':
      - 'nss'
      - 'pam'
  'domain/ad.example.com':
    'ad_domain': 'ad.example.com'
    'ad_server':
      - 'server01.ad.example.com'
      - 'server02.ad.example.com'
    'krb5_realm': 'AD.EXAMPLE.COM'
    'realmd_tags': 'joined-with-samba'
    'cache_credentials': true
    'id_provider': 'ad'
    'krb5_store_password_if_offline': true
    'default_shell': '/bin/bash'
    'ldap_id_mapping': false
    'use_fully_qualified_names': false
    'fallback_homedir': '/home/%d/%u'
    'access_provider': 'simple'
    'simple_allow_groups':
      - 'admins'
      - 'users'
```

Will be represented in sssd.conf like this:

```ini
[sssd]
domains = ad.example.com
config_file_version = 2
services = nss, pam

[domain/ad.example.com]
ad_domain = ad.example.com
ad_server = server01.ad.example.com, server02.ad.example.com
krb5_realm = AD.EXAMPLE.COM
realmd_tags = joined-with-samba
cache_credentials = true
id_provider = ad
krb5_store_password_if_offline = true
default_shell = /bin/bash
ldap_id_mapping = false
use_fully_qualified_names = false
fallback_homedir = /home/%d/%u
access_provider = simple
simple_allow_groups = admins, users
```

Tip: Using 'ad' as `id_provider` require you to run 'adcli join domain' on the target node. *adcli join* creates a computer account in the domain for the local machine, and sets up a keytab for the machine.

Example:

```bash
$ sudo adcli join ad.example.com
```

Or you can use a relevant [module][1] for automation.

## Limitations

This module supports Puppet >= 7.0.0 and < 9.0.0 (including OpenVox 8.x).

Requires puppetlabs-stdlib >= 8.0.0 < 10.0.0.

### Supported platforms

* RedHat / CentOS / Rocky / AlmaLinux / OracleLinux 8, 9, 10
* Debian 11, 12, 13
* Ubuntu 20.04, 22.04, 24.04

## Credits

* Originally developed as [sgnl05/sssd](https://github.com/sgnl05/sgnl05-sssd)
* sssd.conf template from [walkamongus-sssd][2] by Chadwick Banning
* See `CHANGELOG.md` file for additional credits

[0]: https://docs.pagure.org/SSSD.sssd/
[1]: https://forge.puppet.com/modules?sort=rank&q=adcli
[2]: https://github.com/walkamongus/sssd
