class Gem::Specification
  alias_method :__licenses, :licenses

  def licenses
    ary = (__licenses || []).keep_if { |l| l.length > 0 }
    ary.length == 0 ? guess_licenses : ary
  end

  def guess_licenses
    licenses = []
    Dir.foreach(full_gem_path) do |filename|
      filename_without_extension = File.basename(filename, File.extname(filename)).downcase
      if filename_without_extension.include?("license")
        parts = filename.split('-')
        if (parts.length >= 2)
          licenses << parts[0].upcase
        else
          licenses = licenses + (guess_licenses_from_file_contents File.join(full_gem_path, filename))
        end
      elsif filename_without_extension.include?("readme")
        licenses = licenses + (guess_licenses_from_file_contents File.join(full_gem_path, filename))
      end
    end
    licenses << :unknown if licenses.length == 0
    puts "#{name} - #{licenses}"
    licenses
  end

  private

  def guess_licenses_from_file_contents(path)
    licenses = []
    begin
      File.open(path) do |f|
        data = f.read

        # positive matches
        matches = [
          /under the same license as (?<l>[\s\w]+)/i,
          /released under the (?<l>[\s\w]+) license/i,
          /same license as (?<l>[\s\w]+)/i,
          /(?<l>[\s\w]+) License, see/i,
          /the (?<l>[\s\w]+) license/i,
          /license: (?<l>[\s\w]+)/i,
          /released under the (?<l>[\s\w]+) license/i,
        ]

        matches.each do |r|
          match = data.scan(r).flatten.first
          match = match.strip.gsub(/\n/, ' ').gsub(/  +/, ' ') if match
          licenses << match if match and match.size > 0
        end

        # Replace all newlines with spaces.
        data = data.gsub(/\n/, ' ')
        # Make all places with more than one space into one space.
        data = data.gsub(/  +/, ' ')

        license_options = {
          'MIT' => /Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files \(the "Software"\), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and\/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:/,
          "Ruby" => /Ruby.s licence/
        }

        license_options.each do |license, text|
          licenses << license if Regexp.new(text, 'i').match(data)
        end
      end
    rescue Exception => e
      puts "Exception processing #{name} - #{path}: #{e}"
    end
    licenses
  end

end

