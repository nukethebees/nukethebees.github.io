module Jekyll
  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      if site.config['category_pages']
        site.config['category_pages'].each do |cat|
          category_name = cat['category']
          posts = site.categories[category_name] || []

          site.pages << CategoryPage.new(site, site.source, cat, posts)
        end
      end
    end
  end

  class CategoryPage < Page
    def initialize(site, base, config_entry, posts)
      @site = site
      @base = base
      @dir  = config_entry['permalink'].sub(%r{^/|/$}, '')  # remove leading/trailing slash
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, "_layouts"), "category_list.html")

      self.data["title"]    = config_entry['title'] || config_entry['category'].capitalize
      self.data["category"] = config_entry['category']
      self.data["posts"]    = posts
    end
  end
end