module RancherOnEks
  class WrapupController < RancherOnEks::ApplicationController

    def show
      download_file if params[:download]

      @lasso_commands = ["done"].include? Rails.configuration.lasso_commands
      @resources_deleted = Step.all_deleted?
      @in_process = params[:deleting] && !@resources_deleted
      @fqdn = RancherOnEks::Fqdn.load.value
      @region = AWS::Region.load.value
      @cluster_name = Resource.find_by(type: 'AWS::Cluster')
      @cluster_name = @cluster_name.id unless @cluster_name.nil?
      @password = nil if @in_process
      @password = Helm::Rancher.last&.initial_password unless @in_process
      @resources = Resource.all
      # do not show any text if cleaning up
      @cleaning_up = params[:deleting]
      # keep showing the buttons after cleaning up
      @resources_created = @resources.length > 0 || params[:deleting]
      @downloading = ["running"].include? Rails.configuration.lasso_commands
      @failed = true if Rails.configuration.lasso_error != ""
      @failed_error = Rails.configuration.lasso_error
      @in_process = nil if @failed
      @refresh_timer = 15 if @in_process || @downloading
      if @lasso_commands && File.exist?(Rails.configuration.lasso_commands_file)
        @commands = get_commands
      end
    end

    def destroy
      Rails.configuration.lasso_run = params[:run]
      deleting = true if Rails.configuration.lasso_run.present?

      Rails.configuration.lasso_commands = "running" unless deleting
      File.delete(Rails.configuration.lasso_commands_file) unless deleting || !File.exist?(Rails.configuration.lasso_commands_file)
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
      compressed_filestream = zip_files(Rails.configuration.lasso_commands_file)
      @zip_name = "#{t('engines.rancher_on_eks.wrapup.clean_resources_file').downcase.gsub(' ', '_')}"\
        "-#{DateTime.now.iso8601}.zip"
      send_data compressed_filestream.read, filename: @zip_name
    end

    def get_commands
      File.open(Rails.configuration.lasso_commands_file, 'r') { |f| f.readlines }
    end
  end
end
