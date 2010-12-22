Factory.define :credit_card, :class => CreditOfficer::CreditCard do |c|
  c.number "4111111111111111"
  c.provider_name 'visa'
  c.expiration_month 1
  c.expiration_year { Time.now.advance(:year => 1) }
  c.name_on_card "John Smith"
  c.verification_value "1434"
end
