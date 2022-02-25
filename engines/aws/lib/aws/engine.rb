module Aws
  class Engine < ::Rails::Engine
    isolate_namespace Aws

    config.after_initialize do

    end
  end
end
