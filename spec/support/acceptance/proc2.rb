#!/opt/puppetlabs/puppet/bin/ruby

File.write('/tmp/proc2', 'hello world!')

puts 'done processing'

STDERR.puts('stderrmessage')

exit 5
