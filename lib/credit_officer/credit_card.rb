require "active_support/core_ext/class/attribute_accessors"
require "active_support/ordered_hash"
require "luhney_bin"

module CreditOfficer
  #ActiveModel compliant class that represents credit card information
  #Use this to populate and validate credit card details
  #
  #It is not recommended that you persist credit card information unless
  #you absolutely must. Many payment processors proviider you with a mechanism to
  #store this private information
  #
  #@example
  #  cc = CreditOfficer::CreditCard.new({
  #    :number => "411111111111111",
  #    :provider_name => "visa",
  #    :name_on_card => "John Doe",
  #    :expiration_year => 2010,
  #    :expiration_month => 1
  #  }).valid? => true
  #
  #  cc.number = ""
  #  cc.valid? => false 
  #  cc.errors.full_messages => ["Number can't be blank"]
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
    
    #[String] the number found on card
    attr_accessor :number

    #[String] the name found on the front of the card
    attr_accessor :name_on_card

    #[Integer] the integer based representation of the month when the credit card expires (1-12 e.g)
    attr_accessor :expiration_month

    #[Integer] the year when the credit card expires
    #@note paired with the month, this must be in the future for the credit card to be valid
    attr_accessor :expiration_year

    #[String] the CVV/CVV2 value found on the back or front of cards depending on their brand
    #validation of this string can be turned off via class setting require_verification_value
    attr_accessor :verification_value

    #[String] downcased name of the credit card provider 
    #(see {PROVIDERS_AND_FORMATS} for a valid list
    attr_accessor :provider_name
    
    #[Integer] Solo or Switch card attribute representing the start date found on the card
    attr_accessor :start_month

    #[Integer] Solo or Switch card attribute representing the start year found on the card
    attr_accessor :start_year

    #[String] Solo or Switch Card attribute representing the issue number found on the card
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

    #set this flag accordingly to enable/disable validating verification codes 
    #(CVV/CVV2)
    #@note defaults to true
    cattr_accessor :require_verification_value
    self.require_verification_value = true

    #set this flag accordingly if you want CreditOfficer to attempt to derive 
    #the provider name before validation takes place
    #@note defaults to true
    cattr_accessor :automatically_derive_provider_name
    self.automatically_derive_provider_name = true
 
    #checks the configuration setting require_verification_value to see if 
    #verification is required
    def self.verification_value_required?
      require_verification_value
    end
    
    #@return [CreditOfficer::MonthYearPair] month year pair that represents the expiration date
    def expiration_date
      CreditOfficer::MonthYearPair.new(:month => expiration_month, 
        :year => expiration_year)
    end

    #@return [CreditOfficer::MonthYearPair] month year pair that represents the start date
    #@note this applies to switch and solo cards only
    def start_date
      CreditOfficer::MonthYearPair.new(:month => start_month,
        :year => start_year)
    end
    
    #sets the provider name 
    #@param [String] the provider name you wish to set
    #sets the provider name to its downcased equivalent
    #@example note the downcase
    #  credit_card.provider_name = "VISA" => "visa"
    def provider_name=(provider)
      unless provider.nil?
        @provider_name = provider.downcase
      end
    end
    
    #configure your list of supported providers
    #@param Array<String> providers you wish to support (amex, visa, etc) (refer to {PROVIDERS_AND_FORMATS})
    #@note matches specified providers against the supported whitelist {PROVIDERS_AND_FORMATS}
    def self.supported_providers=(providers)
      @supported_providers = providers.collect{|i| i.downcase} & PROVIDERS_AND_FORMATS.keys
    end

    #@return [Array<String>] list of providers
    #@note defaults to {PROVIDERS_AND_FORMATS}.keys
    def self.supported_providers
      @supported_providers
    end

    self.supported_providers = PROVIDERS_AND_FORMATS.keys

    #@return [Boolean] whether or not the provider name indicates the card is a switch or solo card
    def switch_or_solo?
      SWITCH_OR_SOLO_PROVIDERS.include?(provider_name)
    end

    def derive_provider_name
      self.class.supported_providers_and_formats.each do |name, format|
        if number =~ format
          self.provider_name = name
          return
        end
      end
    end

    def masked_number
      if number.present? && number.size >= 4
        "X" * (number.size - 4) + number[-4..-1]
      end
    end
 
    protected
    def run_validations!
      derive_provider_name if self.class.automatically_derive_provider_name
      super
    end

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
      if (provider_name.present? || self.class.automatically_derive_provider_name) && 
        number.present? 
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
      if !self.class.automatically_derive_provider_name &&
        !self.class.supported_providers.include?(provider_name.try(:downcase))

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
