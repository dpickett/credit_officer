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
    
    def expiration_date
      ExpirationDate.new(:month => expiration_month, 
        :year => expiration_year)
    end
    
    protected
    def expiration_date_is_in_future
      if expiration_date.expired?
        errors.add(:expiration_year, translate(:expired, :scope => [:credit_officer, :errors, :messages], :default => "is expired"))
      end
    end
    
    def expiration_date_is_in_recent_future
      if expiration_date.exceeds_recent_future?
        errors.add(:expiration_year, translate(:exceeds_recent_future, :scope => [:credit_officer, :errors, :messages], :default => "is not a valid year"))
      end
    end
  end
end