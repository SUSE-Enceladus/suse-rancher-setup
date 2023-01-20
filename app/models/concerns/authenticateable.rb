# perform authentication based on the output of cloud-instance-credentials
module Authenticateable
  def credentials
    @credentials ||= File.read(Rails.configuration.nginx_pass_file).strip
  end

  def username_is_valid?(username)
    credentials().split(":")[0] == username
  end

  def password_is_valid?(password)
    salted_password = credentials().split(":")[1]
    salt = salted_password.split("$")[2]

    salted_password == salt_password(salt, password)
  rescue StandardError, Cheetah::ExecutionFailed => e
    return false
  end

  private

  def salt_password(salt, password)
    stdout, stderr = Cheetah.run(
      %W(openssl passwd -apr1 -salt #{salt} #{password}),
      stdout: :capture,
      stderr: :capture,
      logger: Logger.new(Rails.configuration.cli_log)
    )
    stdout.strip
  end
end
