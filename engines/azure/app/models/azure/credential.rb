module Azure
  # singular class for wrapping Azure CLI login
  class Credential < AzureResource
    attr_accessor(:app_id, :password, :tenant)

    validate :can_login

    def create_command()
      self.creation_attributes = {
        app_id: @app_id,
        password: @password,
        tenant: @tenant
      }
      self.id = @app_id
    end

    def can_login
      @api ||= Azure::Interface.new(
        credential: self,
        subscription: Azure::Subscription.load(),
        region: Azure::Region.load()
      )
      begin
        @api.login(credentials: {
          app_id: @app_id, password: @password, tenant: @tenant
        })
      rescue Azure::Interface::LoginError => e
        errors.add(:base, e.message)
        return false
      end
    end

    def set_cli; end
  end
end
