require "active_model"

module CreditOfficer
  class Base
    attr_reader :errors
    extend ActiveModel::Naming
    
    def initialize(attributes = {})
      @errors = ActiveModel::Errors.new(self)
    end
    
    def to_model
      self
    end
    
    def persisted?
      false
    end
    
    def to_key
      nil
    end
    
    def to_param
      nil
    end
    
    def valid?
      errors.empty?
    end
  end
end