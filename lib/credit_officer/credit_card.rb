require "active_support/core_ext/class/attribute_accessors"
require "active_support/ordered_hash"
require "luhney_bin"

module CreditOfficer
  class CreditCard < Base
    PROVIDERS_AND_FORMATS = [
      ['visa'               , /^4\d{12}(\d{3})?$/],
      ['master'             , /^(5[1-5]\d{4}|677189)\d{10}$/],
      ['discover'           , /^(6011|65\d{2}|64[4-9]\d)\d{12}|(62\d{14})$/],
      ['american_express'   , /^3[47]\d{13}$/],
      ['diners_club'        , /^3(0[0-5]|[68]\d)\d{11}$/],
      ['jcb'                , /^35(28|29|[3-8]\d)\d{12}$/],
      ['switch'             , /^6759\d{12}(\d{2,3})?$/],
      ['solo'               , /^6767\d{12}(\d{2,3})?$/],
      ['dankort'            , /^5019\d{12}$/],
      ['maestro'            , /^(5[06-8]|6\d)\d{10,17}$/],
      ['forbrugsforeningen' , /^600722\d{10}$/],
      ['laser'              , /^(6304|6706|6771|6709)\d{8}(\d{4}|\d{6,7})?$/]
    ].inject(ActiveSupport::OrderedHash.new) do |ordered_hash, name_format_pair|
      ordered_hash[name_format_pair[0]] = name_format_pair[1]
      ordered_hash
    end

    SWITCH_OR_SOLO_PROVIDERS = [
      'switch',
      'solo'
    ]
    
    attr_accessor :number
    attr_accessor :name_on_card
    attr_accessor :expiration_month
    attr_accessor :expiration_year
    attr_accessor :verification_value
    attr_accessor :provider_name
    
    #SOLO or Switch attributes
    attr_accessor :start_month
    attr_accessor :start_year
    attr_accessor :issue_number

    alias_method :brand, :provider_name
    
    validates_presence_of :number
    validates_presence_of :name_on_card
    
    validates_presence_of :verification_value, 
      :if => proc{|p| p.class.verification_value_required? }
    
    validates_inclusion_of :expiration_month, 
      :in => 1..12  

    validates_presence_of :expiration_year
    
    validate :expiration_date_is_in_future
    validate :expiration_date_is_in_recent_future
    validate :number_is_valid
    validate :provider_name_is_supported

    #SOLO or Switch validations
    validates_presence_of :start_month,
      :if => proc{|cc| cc.switch_or_solo? }

    validates_presence_of :start_year,
      :if => proc{|cc| cc.switch_or_solo? }
    
    validate :issue_number_is_valid,
      :if => proc{|cc| cc.switch_or_solo? }

    validate :start_date_is_in_the_past,
      :if => proc{|cc| cc.switch_or_solo? }

    cattr_accessor :require_verification_value
    self.require_verification_value = true
 
    def self.verification_value_required?
      require_verification_value
    end
    
    def expiration_date
      CreditOfficer::MonthYearPair.new(:month => expiration_month, 
        :year => expiration_year)
    end

    def start_date
      CreditOfficer::MonthYearPair.new(:month => start_month,
        :year => start_year)
    end
    
    def provider_name=(provider)
      unless provider.nil?
        @provider_name = provider.downcase
      end
    end
    
    def self.supported_providers=(providers)
      @supported_providers = providers.collect{|i| i.downcase} & PROVIDERS_AND_FORMATS.keys
    end

    def self.supported_providers
      @supported_providers
    end

    self.supported_providers = PROVIDERS_AND_FORMATS.keys

    def switch_or_solo?
      SWITCH_OR_SOLO_PROVIDERS.include?(provider_name)
    end

    protected
    I18N_ERROR_SCOPE = [:credit_officer, :errors, :messages]

    def expiration_date_is_in_future
      if expiration_date.valid? && expiration_date.end_is_in_past?
        errors.add(:expiration_year, 
          translate(:expired, 
            :scope   => I18N_ERROR_SCOPE, 
            :default => "is expired"))
      end
    end
    
    def expiration_date_is_in_recent_future
      if expiration_date.valid? && expiration_date.exceeds_recent_future?
        errors.add(:expiration_year, translate(:exceeds_recent_future, 
          :scope   => I18N_ERROR_SCOPE, 
          :default => "is not a valid year"))
      end
    end
    
    def number_is_valid
      if provider_name.present? && number.present? 
        if self.class.supported_providers_and_formats[provider_name].nil? || 
          !(number =~ self.class.supported_providers_and_formats[provider_name]) || 
          !checksum_valid?

          errors.add(:number, translate(:invalid_format, 
            :scope   => I18N_ERROR_SCOPE, 
            :default => "is not a valid card number"))
        end
      end
    end

    def provider_name_is_supported
      unless self.class.supported_providers.include?(provider_name.downcase)
        errors.add(:provider_name, translate(:unsupported_provider,
          :scope   => I18N_ERROR_SCOPE,
          :default => "is not supported"))
      end
    end

    def issue_number_is_valid
      unless issue_number =~ /^\d{1,2}$/
        errors.add(:issue_number, translate(:invalid_issue_number,
          :scope   => I18N_ERROR_SCOPE,
          :default => "is not valid"))
      end
    end

    def start_date_is_in_the_past
      if start_date.valid? && start_date.start_is_in_future?
        errors.add(:start_year, translate(:futuristic_start_date,
          :scope => I18N_ERROR_SCOPE,
          :default => "is in the future"))
      end
    end

    def checksum_valid?
      LuhneyBin.validate(number)
    end

    def self.supported_providers_and_formats
      #match supported providers against constant's whitelist
      valid_supported_providers = supported_providers & PROVIDERS_AND_FORMATS.keys

      supported_providers.inject(ActiveSupport::OrderedHash.new) do |ordered_hash, provider_name|
        ordered_hash[provider_name] = PROVIDERS_AND_FORMATS[provider_name]
        ordered_hash
      end
    end
  end
end
