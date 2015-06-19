module Jekyll
  module TagStripFilter
    def strip_p(input)
      #"alice"
      input.to_s.gsub(/<\/?p>/, '')
    end

    def strip_first_p(input)
      input.to_s.sub(/<p>/, '').sub(/<\/p>/,'')
    end
  end
end

Liquid::Template.register_filter(Jekyll::TagStripFilter)

