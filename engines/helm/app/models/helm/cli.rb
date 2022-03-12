require 'cheetah'
require 'json'

module Helm
  class Cli
    def execute(*args)
      stdout, stderr = Cheetah.run(
        ['helm', *args],
        stdout: :capture,
        stderr: :capture,
        env: {}
      )
    end
  end
end
