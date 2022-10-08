module SqlAnonymizer
  module Anonymizer
    def anonymize_value(value)
      case value
      when nil
        nil
      when TrueClass, FalseClass
        MyFaker.boolean(value)
      when Array
        value.map do |v|
          anonymize_value(v)
        end
      when Hash
        value.each_with_object({}) do |(k,v), h|
          h[k] = anonymize_value(v)
        end
      when Float
        return 0.0 if value.to_f == 0.0
        MyFaker.float(value)
      when Integer
        return 0 if value.to_i == 0
        MyFaker.integer(value)
      when String
        MyFaker.sentence(value)
      else
        anonymize_value(value.inspect).tap do |v|
          l = [value.class.name.length, v.length].min
          v[0, l] = value.class.name[0, l]
        end
      end
    end

    def process_value(old_value, processor)
      return old_value if processor == :pass || processor == [:pass]
      return nil if processor.nil?

      if processor.is_a?(Array)
        processor = processor.first
        values = PG::TextDecoder::Array.new.decode(old_value.gsub("\\\\", "\\"))
        values.map! {|v| process_value(v, processor) }
        return PG::TextEncoder::Array.new(needs_quotation: true).encode(values).gsub(/\\/, "\\\\\\")
      end

      srand(old_value.hash) if $consistent

      case processor
      when :binary
        old_value # this is not something we can process right now
      when :string
        MyFaker.sentence(old_value)
      when :float
        return 0.0 if old_value.to_f == 0.0
        MyFaker.float(old_value)
      when :integer
        return 0 if old_value.to_i == 0
        MyFaker.integer(old_value)
      when :boolean
        MyFaker.boolean(old_value)
      when :date
        MyFaker.date(old_value)
      when :datetime
        MyFaker.time(old_value)
      when :empty_string
        ''
      when :empty_array
        []
      when :empty_hash
        {}
      when :json, :text
        case old_value
        when /\A\{.*\}\Z/, /\A\[.*\]\Z/
          JSON.dump(anonymize_value(JSON.parse(old_value)))
        when /\A---\n/
          YAML.dump(anonymize_value(YAML.parse(old_value)))
        else
          anonymize_value(old_value)
        end
      when :name
        names = old_value.split
        ln = names.pop
        names.map! do |n|
          srand(n.hash) if $consistent
          if n =~ /^[a-z]\.?$/i
            n.sub(/[a-z]/i, MyFaker.letter)
          else
            MyFaker.first_name
          end
        end
        names << begin
          srand(ln.hash) if $consistent
          MyFaker.last_name
        end
        names.join(' ')
      when :city, :company_type, :company_name, :date, :email, :first_name, :job, :last_name, :number_string, :state_abbr, :street_address, :url, :zip_code
        if MyFaker.respond_to?(processor)
          old_value = MyFaker.send(processor, old_value)
          old_value = old_value.to_s if [Date, Time, DateTime].any?{|c| old_value.is_a?(c) }
          old_value
        else
          anonymize_value(old_value)
        end
      else
        anonymize_value(old_value)
      end

    end

  end
end
