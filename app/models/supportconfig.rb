require 'cheetah'

class Supportconfig
  class NotGeneratedError < StandardError; end

  attr_reader :generated_at

  def initialize(dir: Rails.root.join('public'))
    @dir = dir
    @generated_at = KeyValue.get('supportconfig_generated_at')
  end

  def generate()
    stdout, stderr = Cheetah.run(
      %W(
        #{Rails.configuration.supportconfig_bin} -Q -g
        -i psuse_public_cloud,psuse_rancher_setup
        -B #{self.filename_element}
        -R #{@dir}
      ),
      stdout: :capture,
      stderr: :capture,
      logger: Logger.new(Rails.configuration.cli_log)
    )
    @generated_at = DateTime.now
    KeyValue.set('supportconfig_generated_at', @generated_at)
  end

  def generated?()
    !!@generated_at
  end

  def output_filename()
    raise NotGeneratedError unless @generated_at

    'scc_' + self.filename_element + '.' + self.extension
  end

  def output_path()
    raise NotGeneratedError unless @generated_at

    Pathname.new(@dir).join(self.output_filename)
  end

  private

  def extension()
    'tgz' # matches -g argument to `supportconfig`
  end

  def filename_element()
    "suse-rancher-setup_#{Rails.configuration.workflow}"
  end
end
