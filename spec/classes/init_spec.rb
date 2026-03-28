# frozen_string_literal: true

require 'spec_helper'

describe 'sssd' do
  platforms = {
    'el8' => {
      extra_packages: [
        'authselect',
        'oddjob-mkhomedir',
      ],
      manage_oddjobd: true,
      facts_hash: {
        os: {
          'family'  => 'RedHat',
          'name'    => 'RedHat',
          'release' => { 'major' => '8' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'el9' => {
      extra_packages: [
        'authselect',
        'oddjob-mkhomedir',
      ],
      manage_oddjobd: true,
      facts_hash: {
        os: {
          'family'  => 'RedHat',
          'name'    => 'RedHat',
          'release' => { 'major' => '9' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'el10' => {
      extra_packages: [
        'authselect',
        'oddjob-mkhomedir',
      ],
      manage_oddjobd: true,
      facts_hash: {
        os: {
          'family'  => 'RedHat',
          'name'    => 'RedHat',
          'release' => { 'major' => '10' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'debian11' => {
      extra_packages: [
        'libpam-runtime',
        'libpam-sss',
        'libnss-sss',
      ],
      manage_oddjobd: false,
      facts_hash: {
        os: {
          'family'  => 'Debian',
          'name'    => 'Debian',
          'release' => { 'major' => '11' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'debian12' => {
      extra_packages: [
        'libpam-runtime',
        'libpam-sss',
        'libnss-sss',
      ],
      manage_oddjobd: false,
      facts_hash: {
        os: {
          'family'  => 'Debian',
          'name'    => 'Debian',
          'release' => { 'major' => '12' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'ubuntu2004' => {
      extra_packages: [
        'libpam-runtime',
        'libpam-sss',
        'libnss-sss',
      ],
      manage_oddjobd: false,
      facts_hash: {
        os: {
          'family'  => 'Debian',
          'name'    => 'Ubuntu',
          'release' => { 'major' => '20.04' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'ubuntu2204' => {
      extra_packages: [
        'libpam-runtime',
        'libpam-sss',
        'libnss-sss',
      ],
      manage_oddjobd: false,
      facts_hash: {
        os: {
          'family'  => 'Debian',
          'name'    => 'Ubuntu',
          'release' => { 'major' => '22.04' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
    'ubuntu2404' => {
      extra_packages: [
        'libpam-runtime',
        'libpam-sss',
        'libnss-sss',
      ],
      manage_oddjobd: false,
      facts_hash: {
        os: {
          'family'  => 'Debian',
          'name'    => 'Ubuntu',
          'release' => { 'major' => '24.04' },
        },
        networking: { 'domain' => 'example.com' },
      },
    },
  }

  describe 'with default values for parameters on' do
    platforms.sort.each do |k, v|
      context k.to_s do
        let(:facts) do
          v[:facts_hash]
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('sssd') }

        it do
          is_expected.to contain_package('sssd').with(
            ensure: 'installed',
          )
        end

        it do
          is_expected.to contain_package('sssd').that_comes_before('File[sssd.conf]')
        end

        if v[:extra_packages]
          v[:extra_packages].each do |pkg|
            it do
              is_expected.to contain_package(pkg).with(
                ensure: 'installed',
              )
            end

            it do
              is_expected.to contain_package(pkg).that_requires('Package[sssd]')
            end
          end
        end

        if v[:service_dependencies]
          if v[:manage_oddjobd] == true
            before_val = 'Service[oddjobd]'
          else
            before_val = nil
          end

          v[:service_dependencies].each do |svc|
            it do
              is_expected.to contain_service(svc).with(
                ensure: 'running',
                hasstatus: true,
                hasrestart: true,
                enable: true,
                before: before_val,
              )
            end
          end
        end

        if v[:manage_oddjobd] == true
          it do
            is_expected.to contain_service('oddjobd').with(
              ensure: 'running',
              enable: true,
              hasstatus: true,
              hasrestart: true,
            )
          end

          if v[:extra_packages]
            it do
              is_expected.to contain_service('oddjobd').that_requires(
                v[:extra_packages].collect { |pkg| "Package[#{pkg}]" },
              )
            end
          end
        else
          it { is_expected.not_to contain_service('oddjobd') }
        end

        it do
          is_expected.to contain_file('sssd.conf').with(
            ensure: 'file',
            path: '/etc/sssd/sssd.conf',
            owner: 'root',
            group: 'root',
            mode: '0600',
          )
        end

        it do
          is_expected.to contain_file('sssd.conf').with_content(
            %r{^# Managed by Puppet.\n\n\[sssd\]\ndomains = example.com\nconfig_file_version = 2\nservices = nss, pam\n\n\[domain/example.com\]\naccess_provider = simple\nsimple_allow_users = root\n},
          )
        end

        # RedHat family uses authselect
        if v[:facts_hash][:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_exec('authselect-mkhomedir').with(
              command: '/bin/authselect select sssd with-mkhomedir --force',
              unless: "/usr/bin/test \"`/bin/authselect current --raw`\" = \"sssd with-mkhomedir\"",
              require: 'File[sssd.conf]',
            )
          end
        end

        if v[:facts_hash][:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file('/usr/share/pam-configs/pam_mkhomedir').with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0644',
              content: %r{pam_mkhomedir.so umask=0022},
              notify: 'Exec[pam-auth-update]',
            )
          end

          it do
            is_expected.to contain_exec('pam-auth-update').with(
              path: '/bin:/usr/bin:/sbin:/usr/sbin',
              refreshonly: true,
            )
          end
        end

        it do
          is_expected.to contain_service('sssd').with(
            ensure: 'running',
            enable: true,
            hasstatus: true,
            hasrestart: true,
            subscribe: 'File[sssd.conf]',
          )
        end
      end
    end
  end

  # Use el9 as default platform for parameter-specific tests
  let(:facts) do
    {
      os: {
        'family'  => 'RedHat',
        'name'    => 'RedHat',
        'release' => { 'major' => '9' },
      },
      networking: { 'domain' => 'example.com' },
    }
  end

  describe 'with ensure set to valid string absent' do
    let(:params) { { ensure: 'absent' } }

    it { is_expected.to contain_file('sssd.conf').with_ensure('absent') }

    it do
      is_expected.to contain_exec('authselect-mkhomedir').with(
        command: '/bin/authselect select sssd --force',
        unless: "/usr/bin/test \"`/bin/authselect current --raw`\" = \"sssd\"",
      )
    end
  end

  describe 'with config set to valid hash' do
    let(:params) { { config: { 'test' => { 'domains' => 'test.domain.local', 'config_file_version' => 242, 'services' => ['test1', 'test2'] } } } }

    it { is_expected.to contain_file('sssd.conf').with_content(%r{^\[test\]\ndomains = test.domain.local\nconfig_file_version = 242\nservices = test1, test2\n}) }
  end

  describe 'with sssd_package set to valid string sssd-test' do
    let(:params) { { sssd_package: 'sssd-test' } }

    it { is_expected.to contain_package('sssd-test') }
    it { is_expected.to contain_package('authselect').that_requires('Package[sssd-test]') }
  end

  describe 'with sssd_package_ensure set to valid string absent' do
    let(:params) { { sssd_package_ensure: 'absent' } }

    it { is_expected.to contain_package('sssd').with_ensure('absent') }
  end

  describe 'with sssd_service set to valid string sssd-test' do
    let(:params) { { sssd_service: 'sssd-test' } }

    it { is_expected.to contain_service('sssd-test') }
  end

  describe 'with extra_packages set to valid array [test1, test2]' do
    let(:params) { { extra_packages: ['test1', 'test2'] } }

    it { is_expected.to contain_package('test1') }
    it { is_expected.to contain_package('test2') }
  end

  describe 'with extra_packages_ensure set to valid string absent' do
    let(:params) { { extra_packages_ensure: 'absent' } }

    it { is_expected.to contain_package('authselect').with_ensure('absent') }
    it { is_expected.to contain_package('oddjob-mkhomedir').with_ensure('absent') }
  end

  describe 'with config_file set to valid absolute path /test/sssd/sssd.conf' do
    let(:params) { { config_file: '/test/sssd/sssd.conf' } }

    it { is_expected.to contain_file('sssd.conf').with_path('/test/sssd/sssd.conf') }
  end

  describe 'with mkhomedir set to valid boolean false' do
    let(:params) { { mkhomedir: false } }

    it { is_expected.not_to contain_service('oddjobd') }

    platforms.sort.each do |k, v|
      context "on #{k}" do
        let(:facts) do
          v[:facts_hash]
        end

        if v[:facts_hash][:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_exec('authselect-mkhomedir').with(
              command: '/bin/authselect select sssd --force',
              unless: "/usr/bin/test \"`/bin/authselect current --raw`\" = \"sssd\"",
            )
          end
        end

        if v[:facts_hash][:os]['family'] == 'Debian'
          it { is_expected.not_to contain_file('/usr/share/pam-configs/pam_mkhomedir') }
        end


      end
    end
  end

  platforms.sort.each do |k, v|
    describe "with manage_oddjobd set to valid boolean false on #{k}" do
      let(:facts) do
        v[:facts_hash]
      end
      let(:params) { { manage_oddjobd: false } }

      if v[:service_dependencies]
        v[:service_dependencies].each do |svc|
          it { is_expected.to contain_service(svc).with_before(nil) }
        end
      end
      it { is_expected.not_to contain_service('oddjobd') }
    end
  end

  platforms.sort.each do |k, v|
    describe "with manage_oddjobd set to valid boolean true on #{k}" do
      let(:facts) do
        v[:facts_hash]
      end
      let(:params) { { manage_oddjobd: true } }

      if v[:service_dependencies]
        v[:service_dependencies].each do |svc|
          it { is_expected.to contain_service(svc).with_before('Service[oddjobd]') }
        end
      end
      it { is_expected.to contain_service('oddjobd') }
    end
  end

  describe 'with service_ensure set to valid string stopped' do
    let(:params) { { service_ensure: 'stopped', manage_oddjobd: true } }

    it { is_expected.to contain_service('oddjobd').with_ensure('stopped') }

    it do
      is_expected.to contain_service('sssd').with(
        ensure: 'stopped',
        enable: false,
      )
    end
  end

  describe 'with service_dependencies set to valid array [ test1, test2 ]' do
    let(:params) { { service_dependencies: ['test1', 'test2'] } }

    it { is_expected.to contain_service('test1') }
    it { is_expected.to contain_service('test2') }
  end

  describe 'with enable_mkhomedir_flags set to valid array and authselect_profile set to valid string profile' do
    let(:params) { { enable_mkhomedir_flags: ['--enable1', '--enable2'], authselect_profile: 'profile' } }

    platforms.sort.each do |k, v|
      context "on #{k}" do
        let(:facts) do
          v[:facts_hash]
        end

        if v[:facts_hash][:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_exec('authselect-mkhomedir').with(
              command: '/bin/authselect select profile --enable1 --enable2 --force',
              unless: "/usr/bin/test \"`/bin/authselect current --raw`\" = \"profile --enable1 --enable2\"",
            )
          end
        end
      end
    end
  end

  describe 'with disable_mkhomedir_flags set to valid array and mkhomedir false and authselect_profile set to profile' do
    let(:params) { { disable_mkhomedir_flags: ['--disable1', '--disable2'], mkhomedir: false, authselect_profile: 'profile' } }

    platforms.sort.each do |k, v|
      context "on #{k}" do
        let(:facts) do
          v[:facts_hash]
        end

        if v[:facts_hash][:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_exec('authselect-mkhomedir').with(
              command: '/bin/authselect select profile --disable1 --disable2 --force',
              unless: "/usr/bin/test \"`/bin/authselect current --raw`\" = \"profile --disable1 --disable2\"",
            )
          end
        end
      end
    end
  end

  describe 'with ensure_absent_flags set to valid array (and ensure set to absent)' do
    let(:params) { { ensure_absent_flags: ['--absent1', '--absent2'], ensure: 'absent' } }

    platforms.sort.each do |k, v|
      context "on #{k}" do
        let(:facts) do
          v[:facts_hash]
        end

        if v[:facts_hash][:os]['family'] == 'RedHat'
          it do
            is_expected.to contain_exec('authselect-mkhomedir').with(
              command: '/bin/authselect select sssd --absent1 --absent2 --force',
              unless: "/usr/bin/test \"`/bin/authselect current --raw`\" = \"sssd --absent1 --absent2\"",
            )
          end
        end
      end
    end
  end

  describe 'with pam_mkhomedir_umask set to 0077' do
    let(:params) { { pam_mkhomedir_umask: '0077' } }

    platforms.sort.each do |k, v|
      context "on #{k}" do
        let(:facts) do
          v[:facts_hash]
        end

        if v[:facts_hash][:os]['family'] == 'Debian'
          it do
            is_expected.to contain_file('/usr/share/pam-configs/pam_mkhomedir').with(
              ensure: 'file',
              owner: 'root',
              group: 'root',
              mode: '0644',
              content: %r{pam_mkhomedir.so umask=0077},
              notify: 'Exec[pam-auth-update]',
            )
          end
        end


      end
    end
  end

  describe 'variable type and content validations' do
    mandatory_params = {}

    validations = {
      'array' => {
        name: %w[extra_packages service_dependencies enable_mkhomedir_flags disable_mkhomedir_flags ensure_absent_flags],
        valid: [%w[ar ray]],
        invalid: ['invalid', { 'ha' => 'sh' }, 3, 2.42, true, nil],
        message: 'expects an Array value',
      },
      'absolute_path' => {
        name: %w[config_file],
        valid: %w[/absolute/filepath /absolute/directory/],
        invalid: ['./relative/path', %w[ar ray], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        message: 'Evaluation Error: Error while evaluating a Resource Statement',
      },
      'boolean' => {
        name: %w[mkhomedir manage_oddjobd],
        valid: [true, false],
        invalid: ['false', %w[ar ray], { 'ha' => 'sh' }, 3, 2.42, nil],
        message: 'Evaluation Error: Error while evaluating a Resource Statement',
      },
      'hash' => {
        name: %w[config],
        valid: [],
        invalid: ['string', 3, 2.42, %w[ar ray], true, nil],
        message: 'expects a Hash value',
      },
      'string' => {
        name: %w[sssd_package sssd_package_ensure sssd_service extra_packages_ensure authselect_profile],
        valid: %w[string],
        invalid: [%w[ar ray], { 'ha' => 'sh' }, 3, 2.42, true],
        message: 'expects a String',
      },
      'validate_re ensure' => {
        name: %w[ensure],
        valid: %w[absent present],
        invalid: ['string', %w[ar ray], { 'ha' => 'sh' }, 3, 2.42, true, nil],
        message: 'expects a match for Enum',
      },
      'validate_re service_ensure' => {
        name: %w[service_ensure],
        valid: [true, false, 'running', 'stopped'],
        invalid: ['string', %w[ar ray], { 'ha' => 'sh' }, 3, 2.42, nil],
        message: 'Evaluation Error: Error while evaluating a Resource Statement',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid }].reduce(:merge) }

            it { is_expected.to compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid }].reduce(:merge) }

            it 'is expected to fail' do
              expect { is_expected.to contain_class(subject) }.to raise_error(Puppet::PreformattedError, /#{var[:message]}/)
            end
          end
        end
      end
    end
  end
end
