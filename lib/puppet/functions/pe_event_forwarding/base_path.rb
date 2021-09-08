Puppet::Functions.create_function(:'pe_event_forwarding::base_path') do
  def base_path(str, path)
    # No specific path is provided, going to use default path from logdir
    if path.nil?
      base = str[%r{^(.*?)\/puppetlabs\/}]
      !base.nil? ? base : str
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
