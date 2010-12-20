require 'active_support/core_ext/time/calculations'

module CreditOfficer
  class ExpirationDate < Base
    attr_reader :year
    attr_reader :month
    
    def initialize(attrs = {})
      @year = attrs[:year].to_i
      @month = attrs[:month].to_i
    end
    
    def expired? #:nodoc:
      Time.now.utc > actual_date
    end
    
    RECENT_FUTURE_YEAR_LIMIT = 20
    def exceeds_recent_future?
      actual_date <= Time.now.utc.advance(:years => RECENT_FUTURE_YEAR_LIMIT)
    end
    
    def actual_date #:nodoc:
      begin
        Time.utc(year, month, Time.days_in_month(month, year), 23, 59, 59)
      rescue ArgumentError
        Time.at(0).utc
      end
    end
  end
end