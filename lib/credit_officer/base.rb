require "active_model"

module CreditOfficer
  class Base
    extend ActiveModel::Naming
    include ActiveModel::Validations
    extend ActiveModel::Translation
    
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
    
    protected
    def translate(key, options = {})
      I18n.t key, options
    end
  end
end