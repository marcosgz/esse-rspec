# frozen_string_literal: true

require "esse"

require_relative "rspec/version"
require_relative "rspec/class_methods"

module Esse
  module RSpec
  end
end

::RSpec.configure do |config|
  config.include Esse::RSpec::ClassMethods
end
