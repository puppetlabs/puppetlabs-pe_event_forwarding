#!/opt/puppetlabs/puppet/bin/ruby

File.write('/tmp/proc2', File.read(ARGV[0]))

puts 'done processing'

STDERR.puts('stderrmessage')

exit 5
