module RancherOnEks
  class WrapupController < ApplicationController

    def show
      download_file if params[:download]

      @foo = ["done"].include? Rails.application.config.foo
      @resources_deleted = Step.all_deleted?
      @in_process = params[:deleting] && !@resources_deleted
      @fqdn = RancherOnEks::Fqdn.load.value
      @password = nil if @in_process
      @password = RancherOnEks::Rancher.last&.initial_password unless @in_process
      @resources = Resource.all
      @resources_deleted = Step.all_deleted?
      @downloading = ["running"].include? Rails.application.config.foo
      @refresh_timer = 15 if @in_process || @downloading # || @foo
      if @foo && File.exist?('/tmp/delete_resources_steps')
        @commands = get_commands
        creds = AWS::Credential.load
        @substring = "AWS_ACCESS_KEY_ID=AWS_SECRET_ACCESS_KEY=" + creds.aws_access_key_id + creds.aws_secret_access_key + "  "
      end
    end

    def destroy
      Rails.application.config.lasso_run = params[:run]
      deleting = true if Rails.application.config.lasso_run.present?

      Rails.application.config.foo = "running" unless deleting
      RancherOnEks::WrapupJob.perform_later()
      redirect_to rancher_on_eks.wrapup_path(deleting: deleting)
    end

    def zip_files(file)
      compressed_filestream = Zip::OutputStream.write_buffer do |zos|
        zos.put_next_entry(File.basename(file))
        zos.print(File.read(file))
      end
      compressed_filestream.rewind

      return compressed_filestream
    end

    def download_file
      compressed_filestream = zip_files('/tmp/delete_resources_steps')
      @zip_name = "#{t('clean_resources_file').downcase.gsub(' ', '_')}"\
        "-#{DateTime.now.iso8601}.zip"
      send_data compressed_filestream.read, filename: @zip_name
    end

    def get_commands
      File.open('/tmp/delete_resources_steps', 'r') { |f| f.readlines }
    end
  end
end
