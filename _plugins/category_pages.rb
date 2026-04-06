require_relative 'debug_utils'

module Jekyll
  class CategoryPageGenerator < Generator
    safe true

    def generate(site)
      debug = DebugUtils.env_flag('DEBUG_CATEGORY_CONFIG_GEN')
      defined_categories = {}

      site.config['category_pages'] = []
      site.categories.each do |category_name, posts|
        cat_entry = {
          'title'     => category_name.capitalize,
          'category'  => category_name,
          'permalink' => "/#{category_name.downcase}/"
        }

        if debug
          puts "Generating config for category: #{category_name} #{cat_entry}"
        end

        new_page = CategoryPage.new(site, site.source, cat_entry, posts)
        existing_page = site.pages.find { |p| p.url == new_page.url }
        if debug
            puts "Existing page #{new_page.url} : #{!!existing_page}"
        end
        if existing_page
          puts "Reusing page"
          idx = site.pages.index(existing_page)
          site.pages[idx] = new_page
        else
          puts "Adding page"
          site.pages << new_page
        end
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
