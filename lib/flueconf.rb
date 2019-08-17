module Flueconf
  def build(*args, &block)
    Flueconf::Builder.new(*args, &block)
  end
  module_function :build
end

require 'flueconf/builder'
require 'flueconf/serializer'
require 'flueconf/version'
