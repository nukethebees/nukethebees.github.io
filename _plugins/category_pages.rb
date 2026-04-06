require_relative 'debug_utils'

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
      debug = DebugUtils.env_flag('DEBUG_CATEGORY_GEN')

      @site = site
      @base = base
      # remove leading/trailing slash
      @dir  = config_entry['permalink'].sub(%r{^/|/$}, '')
      @name = "index.html"

      self.process(@name)
      self.read_yaml(File.join(base, "_layouts"), "category_list.html")

      self.data["title"]    = config_entry['title']
      self.data["category"] = config_entry['category']
      self.data["posts"]    = posts

      if debug
        puts "Cat: #{self.data["category"]}"
        puts "Posts"
        for post in self.data["posts"]
          puts "    #{post.data["title"]}"
          puts "    #{post.url}"
        end
      end
    end
  end
end
