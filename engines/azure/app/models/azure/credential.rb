module Azure
  # singular class for wrapping Azure CLI login
  class Credential
    include ActiveModel::Model

    attr_accessor(:app_id, :password, :tenant)

    def login
      self.login!
    rescue Azure::Cli::CliError => e
      self.errors.add(:base, e.message)
      return false
    end

    def login!
      @cli ||= Azure::Cli.load()
      @cli.login(app_id: self.app_id, password: self.password, tenant: self.tenant)
    end
  end
end
