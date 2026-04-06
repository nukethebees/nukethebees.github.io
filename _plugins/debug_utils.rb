module DebugUtils
  # Reads a CLI variable and converts it to boolean
  # e.g.
  # MY_FLAG=1 bundle exec jekyll serve (true)
  # MY_FLAG=0 bundle exec jekyll serve (false)
  def self.env_flag(var_name)
    val = ENV[var_name]
    return val && val.to_i != 0
  end
end
