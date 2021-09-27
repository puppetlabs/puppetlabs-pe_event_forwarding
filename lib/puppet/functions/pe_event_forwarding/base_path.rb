# This custom function returns the base path of any given string
# argument. If a desired path is not passed in, it will match the
# default str argument up to `puppetlabs`.
Puppet::Functions.create_function(:'pe_event_forwarding::base_path') do
  # @param str The backup path to set; default
  # @param path The desired path
  # @return [String] Returns a string
  # @example Calling the function
  #   pe_event_forwarding::base_path(default_path, desired_path)
  def base_path(str, path)
    # No specific path is provided, going to use default path from logdir
    if path.nil?
      base = str.match(%r{^(.*?\/puppetlabs)\/})
      !base.nil? ? base[1] : str
    # A specfic path is provided
    else
      path_arr = path.split('/')
      if path_arr.length >= 2
        path_arr.pop(2)
      end
      path_arr.join('/')
    end
  end
end
