$LOAD_PATH.push File.expand_path(__dir__, '..')
require "rancher_on_eks/engine"

module RancherOnEks
  def self.menu_entries
    [
      { caption: 'Domain Name', icon: 'read_more', target: '/deploy/fqdn/edit' },
      { caption: 'Security Options', icon: 'lock', target: '/deploy/security/edit' },
      PreFlight.menu_entry,
      { caption: 'Deploy', icon: 'deploy', target: '/deploy/steps' },
      { caption: 'Next Steps', icon: 'enhancement', target: '/deploy/wrapup' }
    ]
  end

  def self.load_pre_flight_checks!
    PreFlight::Check.find_or_create_by(
      name: 'aws_vpc_quota',
      job: 'AWS::VpcQuotaCheckJob'
    )
  end

  def self.preflight_check_count
    1
  end
end
