$LOAD_PATH.push File.expand_path(__dir__, '..')
require "rancher_on_aks/engine"

module RancherOnAks
  def self.menu_entries
    [
      { caption: 'Domain Name', icon: 'read_more', target: '/deploy/fqdn/edit'},
      { caption: 'Security Options', icon: 'lock', target: '/deploy/security/edit' },
      PreFlight.menu_entry,
      { caption: 'Deploy', icon: 'deploy', target: '/deploy/steps'},
      { caption: 'Next Steps', icon: 'enhancement', target: '/deploy/wrapup'}
    ]
  end

  def self.load_pre_flight_checks!
    PreFlight::Check.find_or_create_by(
      name: 'azure_vcpu_quota',
      job: 'RancherOnAks::VcpuQuotaCheckJob'
    )
    PreFlight::Check.find_or_create_by(
      name: 'azure_public_ip_address_quota',
      job: 'Azure::PublicIpAddressQuotaCheckJob'
    )
  end
end
