class Resource < ApplicationRecord
  # because STI
  has_many :steps, foreign_key: 'resource_id', inverse_of: 'resource'

  serialize :creation_attributes
  attr_reader :response

  after_find :parse_response

  private

  def parse_response
    @response = begin
      JSON.parse(self.framework_raw_response)
    rescue
      nil
    end
  end
end
