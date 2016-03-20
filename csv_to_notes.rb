require 'csv'
# require 'securerandom'
# SecureRandom.uuid

class Row
  attr_reader :raw, :chapter, :part, :id, :type, :prompt, :problem, :solution

  def initialize(raw)
    @raw = raw
    self.attributes = raw.values
  end

  def attributes
    [@chapter, @part, @id, @type, @prompt, @problem, @solution]
  end

  def attributes=(val)
    @chapter, @part, @id, @type, @prompt, @problem, @solution = val
  end

  def key
    @key ||= begin
      chapter_key = chapter.split(' ')[0]
      part_key = part.split(' ')[0].tr('.', '-')
      "#{chapter_key}_#{part_key}_#{id}"
    end
  end

  def download_images!
    image_urls.each_with_index do |image_url, index|
      image_name = image_names[index]
      `curl #{image_url} > ./media/#{image_name}`
    end
  end

  def replace_image_urls!
    image_urls.each_with_index do |image_url, index|
      image_name = image_names[index]
      solution.sub!(image_url, "<img src=\"#{image_name}\">")
    end
    solution.gsub!("\n", "<br>")
  end

  def image_names
    @image_names ||=
      image_urls.each_with_index.map do |image_url, index|
        "#{key}_#{index}.png"
      end
  end

  def image_urls
    @image_urls ||= solution.scan(/(https?\:\/\/[^\r\n ]+)/).flatten
  end

  def to_note
    attributes
  end
end

def load_csv(file)
  csv = CSV.parse(File.read(file))
  csv.shift
  csv.map do |row|
    Row.new(Hash[%w[chapter part id type prompt problem solution].zip(row)])
  end
end

file = "./algebra.csv"
rows = load_csv(file)
#rows.each(&:download_images!)
rows.each(&:replace_image_urls!)
CSV.open("./anki_algebra.txt", "wb") do |csv|
  rows.each { |row| csv << row.to_note }
end

