class CellFilter

  def accept value, regexes_as_csv_strings
    regexes_as_string = regexes_as_csv_strings
    regexes_as_string = regexes_as_csv_strings.split(",") if(regexes_as_csv_strings.respond_to?(:split))
    regexes_as_string.each do | regex_as_string |
      begin
        regex = /#{regex_as_string}/
        parts = value
        parts = value.split(",") if(value.respond_to?(:split))
        matches = find_matches(parts, regex)
        return true if parts.size > 0
      rescue RegexpError => e
        raise "Invalid regex #{regex_as_string}: #{e.message}"
      end
    end
    false
  end

  private

  def find_matches parts, regex
    puts "parts before: #{parts}"
    parts.delete_if do |part|
      !(part.strip =~ regex)
    end
    puts "parts after: #{parts}"
  end
end