require_relative 'debug_utils'

module Jekyll
  class SiteGenerator < Generator
    safe true
    priority :low

    def generate(site)
      create_category_pages_data(site)
      build_category_links(site)
    end

    def create_category_pages_data(site)
      debug = DebugUtils.env_flag('DEBUG_CATEGORY_GEN')

      category_map = {}

      site.categories.each do |category_name, posts|
        entry = {
          'title' => category_name.capitalize,
          'category' => category_name,
          'permalink' => "/#{category_name.downcase}/",
          'posts' => posts
        }

        category_map[category_name] = entry

        create_or_replace_page(site, entry, debug)
      end

      site.data['category_pages'] = category_map
    end

    def create_or_replace_page(site, entry, debug)
      new_page = CategoryPage.new(
        site,
        site.source,
        entry,
        entry['posts']
      )

      existing = site.pages.find do |p|
        p.is_a?(CategoryPage) && p.url == new_page.url
      end

      if existing
        puts "Replacing #{new_page.url}" if debug
        idx = site.pages.index(existing)
        site.pages[idx] = new_page
      else
        puts "Adding #{new_page.url}" if debug
        site.pages << new_page
      end
    end

    def build_category_links(site)
      category_map = site.data['category_pages'] || {}

      category_links =
        category_map.values
                    .map do |cat|
                      {
                        'title' => cat['title'],
                        'url' => cat['permalink']
                      }
                    end
                    .sort_by { |l| l['title'].downcase }

      site.data['category_links'] = category_links
    end
  end

  class CategoryPage < Page
    def initialize(site, base, entry, posts) # rubocop:disable Lint/MissingSuper
      @site = site
      @base = base
      @dir  = entry['permalink'].sub(%r{^/|/$}, '')
      @name = 'index.html'

      process(@name)
      read_yaml(File.join(base, '_layouts'), 'category_list.html')

      data['title']    = entry['title']
      data['category'] = entry['category']
      data['posts']    = posts
    end
  end
end
