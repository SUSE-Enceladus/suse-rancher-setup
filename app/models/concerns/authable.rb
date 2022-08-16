# perform authorization based on the output of cloud-instance-credentials
module Authable
  def credentials
    @credentials ||= File.read(Rails.application.config.nginx_pass_file).strip
  end

  def username_is_valid?(username)
    credentials().split(":")[0] == username
  end

  def password_is_valid?(password)
    salted_password = credentials().split(":")[1]
    salt = salted_password.split("$")[2]

    salted_password == salt_password(salt, password)
  rescue StandardError, Cheetah::ExecutionFailed
    return false
  end

  private

  def salt_password(salt, password)
    Cheetah.run(
      %W(openssl passwd -apr1 -salt #{salt} #{password}),
      stdout: :capture,
      logger: Logger.new(Rails.application.config.cli_log)
    ).strip
  end
end
