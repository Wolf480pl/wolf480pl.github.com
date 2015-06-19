module Jekyll
  module TagStripFilter
    def strip_p(input)
      #"alice"
      input.to_s.gsub(/<\/?p>/, '')
    end
  end
end

Liquid::Template.register_filter(Jekyll::TagStripFilter)

