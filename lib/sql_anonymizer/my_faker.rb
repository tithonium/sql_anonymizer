module SqlAnonymizer
  module MyFaker

    WORDS_BY_LENGTH = Faker::Base.translate('faker.lorem.words').group_by(&:length)
    LETTERS = ('A'..'Z').to_a

    class << self

      def boolean(*)
        rand(1000) < 500 ? true : false
      end

      def first_name(*)
        @first_names ||= Faker::Base.translate('faker.name.male_first_name') + Faker::Base.translate('faker.name.female_first_name')
        @first_names.sample
      end

      def last_name(*)
        @last_names ||= Faker::Base.translate('faker.name.last_name')
        @last_names.sample
      end

      def name(*)
        first_name + ' ' + last_name
      end

      def job(*)
        @job_fields ||= Faker::Base.translate('faker.job.field')
        @job_positions ||= Faker::Base.translate('faker.job.position')
        @job_fields.sample + ' ' + @job_positions.sample
      end

      def number_string(v = '123-45-6789')
        v.gsub(/\d/){ rand(10).to_s }
      end

      def company_type(*)
        @industries ||= Faker::Base.translate('faker.company.industry')
        @industries.sample
      end

      def company_name(*)
        @company_suffixes ||= Faker::Base.translate('faker.company.suffix')
        case rand(1..3)
        when 1
          last_name + ' ' + @company_suffixes.sample
        when 2
          last_name + '-' + last_name
        when 3
          "#{last_name}, #{last_name}, and #{last_name}"
        end
      end

      def integer(val, *)
        return 0 if val.to_i == 0
        sign = _sign(val)
        mag = _magnitude(val)
        min = (10 ** (mag - 0))
        max = (10 ** (mag + 1)) - 1
        val = sign * _integer(min, max)
        val = -2147483648 if val < -2147483648
        val  = 2147483647 if val > 2147483647
        val
      end

      def float(val, *)
        return val if val.to_f == 0.0
        whole, fraction = val.to_s.split('.') ; fraction ||= '0'
        whole = whole == "-0" ? whole : integer(whole)
        fraction = "%.*d" % [fraction.length, integer(fraction)]
        [whole, fraction].join('.').to_f.round(fraction.length)
      end

      def _year(val = nil)
        return _integer(1900, 2100) if val.nil?
        @@now ||= Date.today
        val = Time.parse(val) if val.is_a?(String)
        if val.to_date > @@now
          _integer(@@now.year + 1, 2100)
        else
          _integer(1900, @@now.year - 1)
        end
      end

      def date(val, *)
        Date.new( _year(val), _integer(1, 12), _integer(1, 28) )
      end

      def time(val, *)
        Time.new( _year(val), _integer(1, 12), _integer(1, 28), _integer(0, 23), _integer(0, 59), _integer(0, 59), _integer(-23, 23) * 3600 )
      end
      alias :datetime :time

      def domain_name(*)
        @domain_suffixes ||= Faker::Base.translate('faker.internet.domain_suffix')
        last_name.downcase.tr('_-', '') + '.' + @domain_suffixes.sample
      end

      def username(*)
        "#{first_name[0]}.#{last_name}"
      end

      def email(*)
        "#{username}@#{domain_name}"
      end

      def street_address(*)
        @street_suffixes ||= Faker::Base.translate('faker.address.street_suffix')
        "#{rand(111..99999)} #{rand(0..1) == 0 ? first_name : last_name} #{@street_suffixes.sample}"
      end

      def city(*)
        @city_prefixes ||= Faker::Base.translate('faker.address.city_prefix')
        @city_suffixes ||= Faker::Base.translate('faker.address.city_suffix')
        "#{rand(0..1) == 0 ? nil : @city_prefixes.sample} #{rand(0..1) == 0 ? first_name : last_name}#{rand(0..1) == 0 ? nil : @city_suffixes.sample}".strip
      end

      def state_abbr(*)
        @state_abbrs ||= Faker::Base.translate('faker.address.state_abbr')
        @state_abbrs.sample
      end

      def zip_code(v="", *)
        if v.length == 10
          "%5.5d-%4.4d" % [rand(99999), rand(9999)]
        else
          "%5.5d" % rand(99999)
        end
      end

      def country_code(*)
        'US'
      end

      def url(*)
        "http://example.com/users/#{username}.html"
      end

      def sentence(v, *)
        # v.to_s.gsub(/[A-Z]/, 'A').gsub(/[a-z]/, 'a').gsub(/[0-9]/, '0')
        v.to_s.gsub(/([[:alpha:]]+)/){word($1)}.gsub(/[0-9]/){rand(9).to_s}
      end

      def letter(*)
        LETTERS.sample
      end

      def word(v, *a)
        v = v.to_s
        WORDS_BY_LENGTH[v.length] = [ ((v.length / 8)+1).times.map{WORDS_BY_LENGTH[8].sample}.join[0..v.length] ] * 10 if WORDS_BY_LENGTH[v.length].nil?
        word = WORDS_BY_LENGTH[v.length].sample
        case v
        when /\A[A-Z]+\Z/
          word.upcase
        when /\A[A-Z]([a-z]+)\Z/
          word.capitalize
        else
          word
        end
      end

      def _integer(min = 0, max = Integer::MAX)
        min = 0 if min < 1
        max = Integer::MAX if max > Integer::MAX
        rand(max - min) + min
      end

      def _float(min = 0, max = Integer::MAX)
        rand() * (max - min) + min
      end

      def _magnitude(val)
        return 0 if val.to_i == 0
        Math.log10(val.to_i.abs).floor
      rescue
        STDERR.puts "\n\ninvalid arg for magnitude: #{val.inspect}\n\n"
        1
      end

      def _sign(val)
        v = val.to_i
        return 1 if v == 0
        v / v.abs
      end

    end

  end
end
