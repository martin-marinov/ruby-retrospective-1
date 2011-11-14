class Song
  attr_reader :name, :artist, :genre, :subgenre, :tags

  def initialize(name, artist, genre, subgenre, tags)
    @name = name
    @artist = artist
    @genre = genre
    @subgenre = subgenre
    @tags = tags
  end
end

class Collection
  def initialize(songs_as_string, artist_tags)
    @songs = []
    songs_as_string.each_line do |line|
      name, artist, genre, tags = line.split('.').map(&:strip)
      genre, subgenre = genre.split(',').map(&:strip)
      tags = parse_tags(tags, genre, subgenre, artist, artist_tags)
      @songs << Song.new(name, artist, genre, subgenre, tags)
    end
  end

  def parse_tags(tags, genre, subgenre, artist, artist_tags)
    tags = tags.nil? ? [] : tags.split(',').map(&:strip)
    tags += [genre, subgenre].compact.map(&:downcase)
    tags |= artist_tags.fetch(artist, [])
  end

  def find_tags(tags)
    unwanted_tags = tags.select{ |tag| tag.end_with? '!' }
    wanted_tags = tags - unwanted_tags
    @songs.select do |song|
      (wanted_tags - song.tags).empty? and
      (song.tags & unwanted_tags.map(&:chop)).empty?
    end
  end

  def find(criteria)
    search_result = @songs.dup
    criteria.each { |key, value| search_result &= matching_songs(key, value) }
    search_result
  end

  def matching_songs(key, value)
    case key
      when :name, :artist then @songs.select { |song| song.send(key) == value }
      when :tags then find_tags(Array(value))
      when :filter then @songs.select(&value)
    end
  end
end