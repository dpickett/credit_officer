require 'spec_helper'

describe CreditOfficer::CreditCard do
  TEST_AMEX = "378282246310005"
  TEST_MASTER = "5555555555554444"

  subject { Factory.build(:credit_card) }
  it_should_behave_like "ActiveModel"
  
  should_validate_presence_of :number
  should_validate_presence_of :name_on_card
  should_validate_inclusion_of :expiration_month, :in => 1..12
  should_validate_presence_of :expiration_year
  
  it "validates that the expiration year is on or after this year" do
   subject.expiration_year = Time.now.utc.year - 1 
   subject.should_not be_valid
   subject.errors[:expiration_year].should_not be_blank
  end
  
  it "validates that the expiration year is within 20 years from now" do
    subject.expiration_year = Time.now.utc.year + 21
    subject.should_not be_valid
    subject.errors[:expiration_year].should_not be_blank
  end
  
  it "validates that the expiration month and year is in the future" do
    Timecop.freeze(Time.utc(2010, 11, 1, 1)) do
      subject.expiration_year = "2010"
      subject.expiration_month = "10"
      subject.should_not be_valid
      subject.errors[:expiration_year].should_not be_blank
    end
  end
  
  it "validates the presence of a verification value if it's enabled" do
    old_setting = CreditOfficer::CreditCard.require_verification_value
    CreditOfficer::CreditCard.require_verification_value = true
    subject.verification_value = ""
    subject.should_not be_valid
    subject.errors[:verification_value].should_not be_blank
    
    CreditOfficer::CreditCard.require_verification_value = old_setting
  end
  
  it "does not validate the presence of a verification if it's not enabled" do
    old_setting = subject.class.require_verification_value
      subject.class.require_verification_value = false
    subject.verification_value = ""
    subject.should be_valid
  end
  
  it "validates the credit card number based on its provider name's format" do
    subject.provider_name = 'visa'
    subject.number = '68293421'
    subject.should_not be_valid
    subject.errors[:number].should_not be_blank
  end
  
  it "checks the checksum of the number" do
    subject.number = "4123456789012345"
    subject.should_not be_valid
    subject.errors[:number].should_not be_blank
  end

  context "supported providers" do
    it "validates that my provider is in the list of supported providers" do
      old_supported_providers = subject.class.supported_providers.dup
      subject.class.supported_providers = ['master']
      subject.should_not be_valid
      subject.errors[:number].should_not be_blank

      #reset supported providers
      subject.class.supported_providers = old_supported_providers
    end

    it "rejects a provider that is not in the whitelist" do
      old_supported_providers = subject.class.supported_providers.dup
      subject.class.supported_providers = ["gaga", "ohlala"]     
      subject.class.supported_providers.should be_empty

      #reset supported providers
      subject.class.supported_providers = old_supported_providers
    end

    it "defaults to the large list of providers" do
      subject.class.supported_providers.should eql(subject.class::PROVIDERS_AND_FORMATS.keys)
    end
  end

  context "switch or solo cards" do
    subject { Factory.build(:switch_credit_card) } 
   
    it { should be_valid }

    it "is switch or solo if the provider name reflects that" do
      [
        "switch",
        "solo"
      ].each do |provider_name|
        subject.provider_name = provider_name
        subject.should be_switch_or_solo
      end
    end

    it "requires a start month" do
      subject.start_month = ""
      subject.should_not be_valid
      subject.errors[:start_month].should_not be_blank
    end

    it "requires a start year" do
      subject.start_year = ""
      subject.should_not be_valid
      subject.errors[:start_year].should_not be_blank
    end

    it "requires a valid issue number" do
      subject.issue_number = ""
      subject.should_not be_valid
      subject.errors[:issue_number].should_not be_blank
    end

    it "requires that the start month is not in the future" do
      subject.start_year = Time.now.year + 1
      subject.should_not be_valid
      subject.errors[:start_year].should_not be_blank
    end
  end

  it "reveals the last 4 digits in your masked card number" do
    subject.masked_number.should =~ /#{subject.number[-4..-1]}$/
  end

  it  "obfuscates all the digits except the last for in your masked card numbers" do 
    subject.masked_number.should =~ /^#{"X" * (subject.number.size - 4)}/
  end

  it "returns a nil masked number if I don't have more than 4 digits in my credit card number" do
    subject.number = ""
    subject.masked_number.should be_nil
  end

  context "deriving provider name" do  
    it "derives visa from a visa formatted card number" do
      subject.provider_name = ""
      subject.derive_provider_name
      subject.provider_name.should eql("visa")
    end

    it "derives master from a mastercard formatted number" do
      subject.provider_name = ""
      subject.number = TEST_MASTER
      subject.derive_provider_name
      subject.provider_name.should eql('master')
    end

    it "derives american express from an amex formatted number" do
      subject.provider_name = ""
      subject.number = TEST_AMEX
      subject.derive_provider_name
      subject.provider_name.should eql('american_express')
    end

    it "does not validate the provider name if provider name derivation is on" do
      subject.provider_name = ""
      subject.number = TEST_AMEX
      subject.should be_valid
      subject.provider_name.should eql('american_express')
    end

    it "should not set an error on provider name if the credit card number is invalid" do
      subject.number = "fasdfas"
      subject.should_not be_valid
      subject.errors[:provider_name].should be_blank
    end
  end
end
