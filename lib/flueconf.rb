module Flueconf
  def build(&block)
    Flueconf::Builder.new(&block)
  end
  module_function :build
end

require 'flueconf/builder'
require 'flueconf/serializer'
require 'flueconf/version'
