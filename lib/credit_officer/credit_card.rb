module CreditOfficer
  class CreditCard < Base
    attr_accessor :number
    attr_accessor :name_on_card
    attr_accessor :expiration_month
    attr_accessor :expiration_year
    
    validates_presence_of :number
    validates_presence_of :name_on_card
    validates_inclusion_of :expiration_month, :in => 1..12
    validates_presence_of :expiration_year
    validate :expiration_date_is_in_future
    validate :expiration_date_is_in_recent_future
    
    protected
    def expiration_date_is_in_future
      
    end
    
    RECENT_FUTURE_YEARS = 20
    def expiration_date_is_in_recent_future
      
    end
  end
end