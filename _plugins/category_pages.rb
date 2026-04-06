require_relative 'debug_utils'

module Jekyll
  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      debug = DebugUtils.env_flag('DEBUG_CATEGORY_CONFIG_GEN')
      defined_categories = {}

      if site.config['category_pages']
        site.config['category_pages'].each do |cat|
          if debug
            puts "Reading category: #{cat['category']}"
          end

          category_name = cat['category']
          defined_categories[category_name] = cat
          posts = site.categories[category_name] || []

          site.pages << CategoryPage.new(site, site.source, cat, posts)
        end
      else
        site.config['category_pages'] = []
      end

      site.categories.each do |category_name, posts|
        cat_entry = {
          'title'     => category_name.capitalize,
          'category'  => category_name,
          'permalink' => "/#{category_name.downcase}/"
        }

        if debug
          puts "Generating config for category: #{category_name}"
          puts "    #{cat_entry}"
        end

        site.config['category_pages'] << cat_entry
        site.pages << CategoryPage.new(site, site.source, cat_entry, posts)
      end
    end
  end

  class CategoryPage < Page
    def initialize(site, base, config_entry, posts)
      debug = DebugUtils.env_flag('DEBUG_CATEGORY_PAGE_GEN')

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
