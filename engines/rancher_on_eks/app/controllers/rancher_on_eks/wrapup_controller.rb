module RancherOnEks
  class WrapupController < ApplicationController

    def show
      @fqdn = RancherOnEks::Fqdn.load()
    end
  end
end
