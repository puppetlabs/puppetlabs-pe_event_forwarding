Facter.add(:common_events_is_pe) do
  setcode do
    File.readable?('/opt/puppetlabs/server/pe_version')
  end
end
