require "active_model"

module CreditOfficer
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Validations
    
    def initialize(attributes = {})

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
  end
end