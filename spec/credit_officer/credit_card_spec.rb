require 'spec_helper'

describe CreditOfficer::CreditCard do
  it_should_behave_like "ActiveModel"
  
  should_validate_presence_of :number
  should_validate_presence_of :name_on_card
  should_validate_inclusion_of :expiration_month, :in => 1..12
  should_validate_presence_of :expiration_year
  
  it "validates that the expiration year is on or after this year" do
   subject.expiration_year = Time.now.year - 1 
   subject.should_not be_valid
   subject.errors[:expiration_year].should_not be_blank
  end
  
  it "validates that the expiration year is within 20 years from now" do
    subject.expiration_year = Time.now.utc.year + 20
    subject.should_not be_valid
    subject.errors[:expiration_year].should_not be_blank
  end
  
  it "validates that the expiration month and year is in the future" do
    Timecop.travel(Time.utc(2010, 11, 1, 1))
    subject.expiration_year = "2010"
    subject.expiration_month = "10"
    subject.should_not be_valid
    subject.errors[:expiration_year].should_not be_blank
  end
end