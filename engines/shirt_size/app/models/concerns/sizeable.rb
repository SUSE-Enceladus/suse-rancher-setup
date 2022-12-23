class Sizeable
  # Parent class for defining the specifics of the cluster based on t-shirt size
  attr_reader :size

  TYPES = %w(small medium large)

  def initialize(*args)
    @size = KeyValue.get('cluster_size', 'small')
  end

  def instance_type
    self.instance_types[TYPES.find_index(@size)]
  end

  def instance_types
    self.class.instance_types
  end

  # Inheriting class API

  def self.instance_types
    raise NotImplementedError
  end

  def instance_count
    raise NotImplementedError
  end

  def zones_count
    raise NotImplementedError
  end
end
