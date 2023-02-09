# Abstract class for defining a standardized CLI model
class Executable
  require 'cheetah'
  require 'json'

  class CliError < StandardError; end

  include ActiveModel::Model

  attr_accessor :region, :tag_scope, :do_record, :do_execute

  def self.load()
    new(
      region: KeyValue.get(:region),
      tag_scope: KeyValue.get('tag_scope', 'suse-rancher-setup'),
      do_record: !!Rails.configuration.record_commands,
      do_execute: !Rails.configuration.record_commands
    )
  end

  def environment()
    raise NotImplementedError
  end

  def command()
    raise NotImplementedError
  end

  def execute(*args)
    record(*args) if @do_record
    cheetah_execute(*args) if @do_execute
  end

  def record(*args)
    env_vars = KeyValue.get(:recorded_env_vars, {})
    env_vars.merge!(self.environment)
    KeyValue.set(:recorded_env_vars, env_vars)

    commands = KeyValue.get(:recorded_commands, [])
    full_command = [self.command, *args.flatten].join(' ')
    commands << full_command
    KeyValue.set(:recorded_commands, commands)
  end

  def cheetah_execute(*args)
    stdout, stderr = Cheetah.run(
      [self.command, *args.flatten.collect(&:to_s)],
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
