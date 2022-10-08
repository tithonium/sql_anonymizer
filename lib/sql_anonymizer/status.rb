module SqlAnonymizer
  module Status
    def say(*s)
      STDERR.print "\b \b" * @previous_line.length if @previous_line
      @previous_line = s.join
      STDERR.print @previous_line
    end

    def say!(*s)
      say(*s)
      STDERR.puts
      @previous_line = nil
    end

    def report_progress
      return unless $report_progress
      count_done = $input.tell
      now = Time.now
      return if $last_reported && (now - $last_reported) < 15
      $last_reported = now
      elapsed_time = now - $start_time
      return if count_done < 1 || elapsed_time < 0.5
      completed_fraction = count_done.to_f / $report_progress
      if completed_fraction >= 0.1 && elapsed_time >= 900
        total_time = elapsed_time / completed_fraction
        remaining_time = total_time - elapsed_time
        say "%.2f%% complete, %s so far, est %s remaining" % [completed_fraction * 100, _hms(elapsed_time), _hms(remaining_time)]
      else
        say "%.2f%% complete, %s so far" % [completed_fraction * 100, _hms(elapsed_time)]
      end
    end

    def _hms(s)
      s = s.to_i
      h, s = s.divmod(3600)
      m, s = s.divmod(60)
      if h > 0
        "%d:%2.2d:%2.2d" % [h, m, s]
      elsif m > 0
        "%d:%2.2d" % [m, s]
      else
        "%ds" % s
      end
    end
  end
end
