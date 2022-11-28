require 'cheetah'

module Azure
  class Cli
    class CliError < StandardError; end

    include ActiveModel::Model

    attr_accessor(:tag_scope)

    def self.load
      cli = new(
        tag_scope: KeyValue.get('tag_scope', 'suse-rancher-setup')
      )
      cli.set_defaults()
      return cli
    end

    def execute(args)
      args.unshift('az').flatten!
      stdout, stderr = Cheetah.run(
        args,
        stdout: :capture,
        stderr: :capture,
        logger: Logger.new(Rails.configuration.cli_log)
      )
      stdout
    rescue Cheetah::ExecutionFailed => e
      Rails.logger.error(
        "Exit status:     #{e.status.exitstatus}\n" \
        "Standard output: #{e.stdout}\n" \
        "Error output:    #{e.stderr}"
      )
      raise CliError.new(e.stderr)
    end

    def set_config(key:, value:)
      self.execute(
        %W(config set #{key}=#{value})
      )
    end

    def get_config(key:)
      stdout = self.execute(
        %W(config get #{key})
      )
      JSON.parse(stdout)['value']
    end

    def set_default_region(region)
      self.set_config(key: 'defaults.region', value: region)
    end

    def set_defaults()
      return if KeyValue.get(:azure_defaults_set, false)

      self.set_config(key: 'core.output', value: 'json')
      self.set_config(key: 'core.disable_confirm_prompt', value: 'true')
      self.set_config(key: 'core.collect_telemetry', value: 'false')
      self.set_config(key: 'core.only_show_errors', value: 'true')
      self.set_config(key: 'core.no_color', value: 'true')
      KeyValue.set(:azure_defaults_set, true)
    end

    def login(app_id:, password:, tenant:)
      # login as a service principal
      # https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli
      response = JSON.parse(self.execute(
        %W(login --service-principal -u #{app_id} -p=#{password} --tenant #{tenant})
      ))
      response.first['user']['name'] == app_id
    end
  end
end
