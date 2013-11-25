RSpec::Matchers.define :be_transformed_to do |expected|
  match do |actual|
    actual == expected.split
  end
end
