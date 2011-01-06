require 'active_support/core_ext/time/calculations'

module CreditOfficer
  #ActiveModel compliant abstraction representing the month/year pairs often found on credit cards
  #
  #For most, the only one found on the front is an expiration date
  #
  #For switch and solo cards, an additional start date might be specified
  class MonthYearPair < Base
    #[Integer] the year (required for validity)
    attr_accessor :year
    
    #[Integer] the numberic representation of the month (1-12) (required for validity)
    attr_accessor :month

    validates_inclusion_of :month,
      :in => 1..12

    validates_presence_of :year

    #@param [Hash] hash of attributes to set
    def initialize(attrs = {})
      self.year = attrs[:year].to_i
      self.month = attrs[:month].to_i
    end
    
    #@return [Boolean] whether the last minute of the month is in the past
    def end_is_in_past? #:nodoc:
      Time.now.utc > end_of_month
    end

    #@return [Boolean] whether the first minute of the month is in the future
    def start_is_in_future?
      Time.now.utc < start_of_month
    end
    
    RECENT_FUTURE_YEAR_LIMIT = 20

    #@return [Boolean] whether the last minute of the month is within the bound of {RECENT_FUTURE_YEAR_LIMIT}
    def exceeds_recent_future?
      end_of_month >= Time.now.utc.advance(:years => RECENT_FUTURE_YEAR_LIMIT)
    end

    #@return [Time, nil] the first minute of the month in UTC or nil if an invalid pair was specified
    def start_of_month 
      begin
        Time.utc(year, month, 1, 0, 0, 1)
      rescue ArgumentError
        nil
      end
    end

    #@return [Time, nil] the last minute of the month in UTC or nil if an invalid pair was specified
    def end_of_month 
      begin
        Time.utc(year, month, Time.days_in_month(month, year), 23, 59, 59)
      rescue ArgumentError
        nil
      end
    end
  end
end
