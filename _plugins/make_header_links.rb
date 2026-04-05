module Jekyll
  class CategoryHeaderGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      manual_links = site.config['header_links'] || []
      category_pages = site.config['category_pages'] || []
      category_links = category_pages.map do |cat|
        {
          'title' => cat['title'],
          'url'   => cat['permalink']
        } || []
      end
      site.data['header_links'] = manual_links + category_links
    end
  end
end