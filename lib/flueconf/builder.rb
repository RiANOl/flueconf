require 'json'

class Flueconf::Builder
  def initialize(options = {}, &block)
    @attributes = {}
    @current = @attributes
    @context = nil

    build(&block) if block_given?
  end

  def build(&block)
    return unless block_given?

    @context = eval('self', block.binding)

    instance_eval(&block)

    self
  end

  def label(*args, &block)
    method = block_given? ? :label : :@label
    add(method, *args, &block)
  end

  %i(type id).each do |method|
    define_method method do |*args, &block|
      add(:"@#{method}", *args, &block)
    end
  end

  %i(source match filter system).each do |method|
    define_method method do |*args, &block|
      add(method, *args, &block)
    end
  end

  def method_missing(method, *args, &block)
    if @context and @context.respond_to?(method)
      @context.send(method, *args, &block)
    else
      add(method, *args, &block)
    end
  end

  def add(*args, &block)
    if block_given?
      obj = {}
      k = args.first.to_sym

      @current[k] = [] unless @current[k].is_a? Array
      @current[k] << obj

      c = obj
      args[1..-1].each do |k|
        obj = {}
        c[k.to_sym] = obj
        c = obj
      end

      previous = @current
      @current = obj
      instance_eval(&block)
      @current = previous
    elsif args.length >= 1
      method = args.shift.to_sym

      value = case args.length
              when 0
                nil
              when 1
                args.first
              else
                args
              end
      value = case value
              when Hash
                value.map { |k, v| v.nil? ? nil : "#{k}:#{v}" }.compact.join(',')
              when Array
                value.compact.join(',')
              else
                value
              end
      @current[method] = value
    else
      raise ArgumentError, "One key and at least one of values are required: #{args.join(',')}"
    end
  end

  def to_fluent(*args)
    Flueconf::Serializer.serialize(@attributes, *args)
  end
end
