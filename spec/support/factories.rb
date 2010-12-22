Factory.define :credit_card, :class => CreditOfficer::CreditCard do |c|
  c.number "4111111111111111"
  c.provider_name 'visa'
  c.expiration_month 1
  c.expiration_year { Time.now.advance(:year => 1) }
  c.name_on_card "John Smith"
  c.verification_value "1434"
end

Factory.define :switch_credit_card, :parent => :credit_card do |c|
  c.number '675900000000000000'
  c.provider_name 'switch'
  c.start_month "01"
  c.start_year "1990"
  c.issue_number "01"
end

Factory.define :credit_date, :class => CreditOfficer::Date do |c|
  c.month 1
  c.year 2010
end
