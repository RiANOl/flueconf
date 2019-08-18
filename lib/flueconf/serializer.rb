require 'json'

class Flueconf::Serializer
  class << self
    def serialize(obj, indent: 2)
      dump(obj, indent: indent)
    end

    private

    def dump(obj, keys: [], indent: 0, depth: 0)
      prefix = ' ' * indent * depth
      key = keys.empty? ? nil : keys.join(' ')

      case obj
      when Array
        obj.map do |v|
          send(__method__, v, keys: keys, indent: indent, depth: depth)
        end.compact.join("\n")
      when Hash
        compacted = keys.empty? || (!obj.empty? && obj.values.all? { |v| v.is_a? Hash })

        str = obj.map do |k, v|
          k = k.to_s.strip

          send(__method__, v, keys: (compacted ? (keys + [k]) : [k]), indent: indent, depth: (compacted ? depth : depth + 1))
        end.compact.join("\n")

        compacted ?  str : "#{prefix}<#{key}>\n" + (str.empty? ? '' : "#{str}\n") + "#{prefix}</#{keys.first}>"
      when Numeric, TrueClass, FalseClass
        (key ? "#{prefix}#{key} " : '') + obj.inspect
      when NilClass
        key ? "#{prefix}#{key}" : nil
      when Regexp
        (key ? "#{prefix}#{key} " : '') + obj.to_s
      else
        (key ? "#{prefix}#{key} " : '') + (/["#]/.match?(obj) ? obj.to_s.to_json : obj.to_s)
      end
    end
  end
end
