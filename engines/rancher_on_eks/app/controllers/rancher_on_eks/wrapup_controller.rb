module RancherOnEks
  class WrapupController < ApplicationController

    def show
      @fqdn = RancherOnEks::Fqdn.load.value
      @password = RancherOnEks::Rancher.last&.initial_password
      @resources = Resource.all
    end
  end
end
