module SqlAnonymizer
  module Mysql
    def handle_create_table(line, input: $input_reader, write_to_output: true)
      $output.print line if write_to_output
      table_name = line[/CREATE TABLE `?(\S+?)`? /, 1].to_sym
      STDERR.puts "Table definition for #{table_name}" if $verbose
      $table_schema[table_name] = {}
      while(line = input.gets)
        report_progress
        $output.print line if write_to_output
        break if line =~ %r{^\).*;\r?\n}
        column_name, column_type = line.match(/\A *`?(\S+?)`? (.+?),?\Z/)[1..2]
        $table_schema[table_name][column_name.to_sym] = parse_column_type(column_type)
      end
      say if $report_progress
    end

    def parse_column_type(column_type)
      array = !!column_type.sub!(/\[\]/, '')
      type = case column_type
      when /\Aboolean/
        :boolean
      when /\Abytea/
        :binary
      when /\Acharacter varying/
        :string
      when /\Adate/
        :date
      when /\Adouble precision/
        :float
      when /\A(bigint|integer)/
        :integer
      when /\Ajson/
        :json
      when /\Atext/
        :text
      when /\Atimestamp/
        :datetime
      when /tsvector/
        :tsvector
      else
        nil # should probably raise an exception and demand to be updated
      end
      [array, type]
    end

    def value_to_sql(value)
      case value
      when true
        "'T'"
      when false
        "'F'"
      when nil
        'NULL'
      when Date, Time, String
        %Q['#{value.to_s}']
      else
        value.to_s
      end
    end

    def process_insert_line(line, table_name, field_list, field_config, column_values)
      new_values = column_values.each_with_index.map do |value, idx|
        if value.nil?
          nil
        elsif value == ''
          ''
        else
          field = field_list[idx]
          process_value(value, field_config[field])
        end
      end
      line = new_values.map{|v| value_to_sql(v) }.join("\t")
      line = construct_insert_line(table_name, field_list, new_values)
      $output.puts line
    end

    # `id`, `name`, `first_year`, `last_year`, `lead_id`, `created_at`, `updated_at`, `department`, `hidden_from_participants`
    def parse_field_list(fields)
      fields.split(/\s*,\s*/).map {|f| f.sub(%r{`(.+)`}, '\1').to_sym }
    end

    # 70,'foo`\\'','Party Games',2021,NULL,NULL,'2021-02-27 01:09:02','2021-02-27 01:09:02','gaming',0
    def parse_value_list(values)
      values = values.chars
      [].tap do |out|
        while values.length > 0
          out << if values[0] == "'"
            parse_string_value(values)
          else
            parse_nonstring_value(values)
          end
        end
      end
    end

    def parse_string_value(values)
      values.shift
      collector = ''
      while values.length > 0
        if values[0] == '\\'
          collector << values.shift
        elsif values[0] == "'"
          values.shift
          if values[0] == ','
            values.shift
            values.shift if values[0] == ' '
          end
          break
        end
        collector << values.shift
      end
      case collector
      when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/
        Time.parse(collector)
      when /^\d{4}-\d{2}-\d{2}$/
        Date.parse(collector)
      else
        collector
      end
    end

    def parse_nonstring_value(values)
      collector = ''
      while values.length > 0
        if values[0] == ','
          values.shift
          values.shift if values[0] == ' '
          break
        end
        collector << values.shift
      end
      case collector
      when 'NULL'
        nil
      when /^\d+$/
        collector.to_i
      when /^\d+\.\d+$/
        collector.to_f
      when /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/
        Time.parse(collector)
      when /^\d{4}-\d{2}-\d{2}$/
        Date.parse(collector)
      else
        collector
      end
    end

    def construct_insert_line(table_name, fields, values)
      fields = fields.map{|f| %Q[`#{f}`] }.join(', ')
      values = values.map{|v| value_to_sql(v) }.join(',')
      %Q[INSERT INTO `#{table_name}` (#{fields}) VALUES (#{values});]
    end

    def handle_insert(line)
      report_progress
      table_name, fields, values = line.match(%r{INSERT INTO `(.+)` \((.+)\) VALUES \((.+)\);})[1..4]
      table_name = table_name.to_sym
      fields = parse_field_list(fields)
      values = parse_value_list(values)
      config = table_config(table_name)

      unless $last_table_inserted == table_name
        STDERR.print "#{(config == :exclude) ? 'Excluding' : 'Copying'} data for #{table_name}..." if $verbose
      end
      $last_table_inserted = table_name
      return if config == :exclude

      if config == :pass
        $output.print line
      else
        process_insert_line(line, table_name, fields, config, values)
      end
    end

  end
end
