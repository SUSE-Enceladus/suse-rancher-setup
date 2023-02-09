# Abstract class for defining a standardized CLI model
class Executable
  require 'cheetah'
  require 'json'

  class CliError < StandardError; end

  include ActiveModel::Model

  attr_accessor :region, :tag_scope

  def self.load()
    new(
      region: KeyValue.get(:region),
      tag_scope: KeyValue.get('tag_scope', 'suse-rancher-setup')
    )
  end

  def environment()
    raise NotImplementedError
  end

  def command()
    raise NotImplementedError
  end

  def execute(*args)
    stdout, stderr = Cheetah.run(
      [self.command, *args.flatten],
      stdout: :capture,
      stderr: :capture,
      env: self.environment,
      logger: Logger.new(Rails.configuration.cli_log)
    )
    if stderr.present?
      self.log_entry(
        retcode: 0,
        stdout: stdout,
        stderr: stderr
      )
      raise CliError.new(e.stderr)
    end
    return stdout
  rescue Cheetah::ExecutionFailed => e
    self.log_entry(
      retcode: e.status.exitstatus,
      stdout: e.stdout,
      stderr: e.stderr
    )
    raise CliError.new(e.stderr)
  end

  def log_entry(retcode:, stdout:, stderr:)
    Rails.logger.error(
      "Exit status:     #{retcode}\n" \
      "Standard output: #{stdout}\n" \
      "Error output:    #{stderr}"
    )
  end
end
