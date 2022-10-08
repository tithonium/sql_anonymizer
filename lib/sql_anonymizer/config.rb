module SqlAnonymizer
  module Config
    def load_config(config_file)
      $config = _deep_symbolize_keys!(YAML.load(IO.read(config_file)))
      $config[:global] ||= {} ; $config[:tables] ||= {}

      $table_schema = {}
    end

    def table_config(table_name)
      table_name = table_name.to_sym
      if $config[:tables][table_name].nil?
        STDERR.puts "Defaulting #{table_name} to #{$table_level_default}" if $verbose
        $config[:tables][table_name] = $table_level_default
      end
      case $config[:tables][table_name]
      when Hash
        columns = $table_schema[table_name].keys
        merged_config = $config[:global].merge($config[:tables][table_name])
        hard_keys, soft_keys = merged_config.keys.partition {|k| k.is_a?(Symbol) }
        final_config = merged_config.select {|k,_| hard_keys.include?(k) }
        pass_by_default = final_config.delete(:_pass_by_default)
        (columns - hard_keys).each do |c|
          final_config[c] = if soft_key = soft_keys.find {|k| k.match(c) }
            merged_config[soft_key]
          elsif %i[boolean binary].include?($table_schema[table_name][c].last)
            :pass
          elsif %i[tsvector].include?($table_schema[table_name][c].last)
            nil
          elsif pass_by_default
            :pass
          else
            $table_schema[table_name][c].last
          end
        end
        final_config.delete_if{|k, _| $table_schema[table_name][k].nil? }
        final_config.each_key {|k| final_config[k] = [final_config[k]] if $table_schema[table_name][k].first }
        final_config
      else
        $config[:tables][table_name]
      end
    end
  end
end
