# frozen_string_literal: true

require "spec_helper"

RSpec.describe Esse::RSpec do
  it "has a version number" do
    expect(Esse::RSpec::VERSION).not_to be_nil
  end
end
