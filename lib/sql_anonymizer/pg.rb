module SqlAnonymizer
  module Pg
    def handle_create_table(line, input: $input_reader, write_to_output: true)
      $output.print line if write_to_output
      table_name = line[/CREATE TABLE (?:"?public"?\.)?"?(\S+?)"? /, 1].to_sym
      STDERR.puts "Table definition for #{table_name}" if $verbose
      $table_schema[table_name] = {}
      while(line = input.gets)
        report_progress
        $output.print line if write_to_output
        break if line == ");\n"
        column_name, column_type = line.match(/\A *"?(\S+?)"? (.+?),?\Z/)[1..2]
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
        't'
      when false
        'f'
      when nil
        '\N'
      else
        value
      end
    end

    def process_copy_line(line, table_name, field_list, field_config)
      column_values = line.chomp.split(/\t/, -1)
      new_values = column_values.each_with_index.map do |value, idx|
        if value == '\N' # null
          nil
        elsif value == ''
          ''
        else
          field = field_list[idx]
          process_value(value, field_config[field])
        end
      end
      line = new_values.map{|v| value_to_sql(v) }.join("\t")
      $output.puts line
    end

    def handle_copy(copy_line)
      table_name, fields = copy_line.match(/COPY (?:"?public"?\.)?"?(\S+?)"? \((.+?)\)/)[1..2]
      table_name = table_name.to_sym
      fields = fields.split(', ').map {|c| c.sub(/\A"(.+)"\Z/, '\1').to_sym }
      config = table_config(table_name)
      $output.print "\\echo Data for #{table_name}...\n\n"
      $output.print copy_line
      STDERR.print "#{(config == :exclude) ? 'Excluding' : 'Copying'} data for #{table_name}..." if $verbose
      start_time = Time.now
      rows = bytes = 0
      chunk_rows = chunk_bytes = 0
      while(line = $input_reader.gets)
        report_progress
        rows += 1
        bytes += line.bytesize
        break if line == "\\.\n"
        next if config == :exclude

        if $rechunk
          chunk_rows += 1
          chunk_bytes += line.bytesize
          if chunk_rows >= 50000 || chunk_bytes >= 10485760
            STDERR.print "." if $verbose
            $output.print "\\.\n"
            $output.print "\n"
            $output.print "\\echo More data for #{table_name}...\n\n"
            $output.print copy_line
            chunk_rows = chunk_bytes = 0
          end
        end

        if config == :pass
          $output.print line
        else
          process_copy_line(line, table_name, fields, config)
        end
      end
      if $verbose
        et = Time.now - start_time
        row_rate = rows / et
        bytes /= 1024
        byte_rate = bytes / et
        say! "%s seconds elapsed for %s rows, %s rows/s [%s kB, %s kB/s]" % [et.round(1).commify, rows.commify, row_rate.round(1).commify, bytes.commify, byte_rate.round(1).commify]
      end
      $output.print line
    end

  end
end
