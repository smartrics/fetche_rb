class CellFilter
  def accept value, regexes_as_csv_strings
    regexes_as_string = regexes_as_csv_strings
    regexes_as_string = regexes_as_csv_strings.split(",") if(regexes_as_csv_strings.respond_to?(:split))
    parts = value
    parts = value.split(",") if(value.respond_to?(:split)) ## its an array otherwise
    count = 0
    count = regexes_as_string.count do | regex_as_string |
      begin
        count_matches(parts, /#{regex_as_string}/) > 0
      rescue RegexpError => e
        raise "Invalid regex #{regex_as_string}: #{e.message}"
      end
    end
    count == regexes_as_string.size
  end

  private

  def count_matches parts, regex
    parts.count { | part | part.strip =~ regex }
  end

end