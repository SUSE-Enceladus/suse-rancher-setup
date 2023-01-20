class Quota
  # Abstract class for defining a standardized quota model
  include ActiveModel::Model

  def initialize(**args)
    super(**args)
    set_cli()
  end

  def limit
    raise NotImplementedError
  end

  def usage
    raise NotImplementedError
  end

  def required_availability
    raise NotImplementedError
  end

  def availability
    self.limit - self.usage
  end

  def sufficient_capacity?
    self.availability >= self.required_availability
  end

  private

  def set_cli()
    raise NotImplementedError
  end
end
