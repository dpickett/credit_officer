require 'spec_helper'

describe CreditOfficer::MonthYearPair do
  should_validate_presence_of :year
  should_validate_inclusion_of :month, :in => 1..12

  subject { Factory.build(:month_year_pair) }

  it "indicates when the end of the month is in the past" do
    freeze_time do
      subject.year = 2009   
      subject.end_is_in_past?.should be_true
    end
  end

  it "indicates when the end of hte month is not in the past" do
    freeze_time do 
      subject.year = 2011
      subject.end_is_in_past?.should be_false
    end
  end

  it "indicates when the start of the month is in the future" do
    freeze_time do
      subject.year = 2011
      subject.start_is_in_future?.should be_true
    end
  end

  it "indicates when the start of the month is not in the future" do
    freeze_time do
      subject.year = 2009
      subject.start_is_in_future?.should be_false
    end
  end

  it "has a nil start of month if the date doesn't make sense" do
    subject.month = 49
    subject.start_of_month.should be_nil
  end

  it "has a nil end of month if the date doesn't make sense" do
    subject.month = 49
    subject.end_of_month.should be_nil
  end

  def freeze_time(time = Time.utc(2010, 1, 1, 0, 0, 1), &block)
    Timecop.freeze(time) do
      yield
    end
  end
end
