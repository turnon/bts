class Bts
  class Item

    attr_reader :element

    def initialize element
      @element = element
      rank; link; title; magnet_link; added; size; files; popularity
    end

    def rank
      @rank ||= element.find('strong').text.to_i
    end

    def link
      @link ||= element.all('a')[0].native.attributes['href']
    end

    def title
      @title ||= element.all('a')[0]['innerHTML']
    end

    def magnet_link
      @magnet_link ||= element.all('.option a')[0].native.attributes['href']
    end

    def added
      @added ||= element.all('.option span b')[0].text
    end

    def size
      @size ||= element.all('.option span b')[1].text
    end

    def files
      @files ||= element.all('.option span b')[2].text
    end

    def popularity
      @popularity ||= element.all('.option span b')[4].text
    end
  end
end
