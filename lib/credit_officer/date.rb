require 'active_support/core_ext/time/calculations'

module CreditOfficer
  class Date < Base
    attr_accessor :year
    attr_accessor :month

    validates_inclusion_of :month,
      :in => 1..12

    validates_presence_of :year

    def initialize(attrs = {})
      self.year = attrs[:year].to_i
      self.month = attrs[:month].to_i
    end
    
    def end_is_in_past? #:nodoc:
      Time.now.utc > end_of_month
    end

    def start_is_in_future?
      Time.now.utc < start_of_month
    end
    
    RECENT_FUTURE_YEAR_LIMIT = 20
    def exceeds_recent_future?
      end_of_month <= Time.now.utc.advance(:years => RECENT_FUTURE_YEAR_LIMIT)
    end
    
    def start_of_month #nodoc
      begin
        Time.utc(year, month, 1, 0, 0, 1)
      rescue ArgumentError
        nil
      end
    end

    def end_of_month #:nodoc:
      begin
        Time.utc(year, month, Time.days_in_month(month, year), 23, 59, 59)
      rescue ArgumentError
        nil
      end
    end
  end
end
