require_relative '../../../files/lib/events_collection/lockfile'

describe 'Lockfile' do
  let(:basepath) { '/tmp' }
  let(:path) { File.join('/tmp', 'events_collection_run.lock') }
  let(:new_lockfile) { CommonEvents::Lockfile.new(basepath) }

  before(:each) do
    File.delete(path) if File.exist?(path)
  end

  it 'sets the correct lockfile path' do
    filepaths = ['/path/path', '/path/', '/path', 'path', '']
    filepaths.each do |filepath|
      expect(CommonEvents::Lockfile.new(filepath).filepath).to eq(File.join(filepath, '/events_collection_run.lock'))
      File.delete(filepath) if File.exist?(filepath)
    end
  end

  it 'requires a lockfile path' do
    expect { CommonEvents::Lockfile.new }.to raise_error(ArgumentError)
  end

  it 'creates the lockfile with the correct format' do
    new_lockfile.write_lockfile
    expect(File.exist?(path)).to be true
    lockfile_contents = JSON.parse(File.read(path))
    expect(lockfile_contents['pid']).to be_an(Integer)
    expect(lockfile_contents['program_name']).to be_a(String)
  end

  it 'checks if the lockfile exists' do
    lockfile = new_lockfile
    expect(lockfile.lockfile_exists?).to be false
    lockfile.write_lockfile
    expect(lockfile.lockfile_exists?).to be true
  end

  it 'can delete the lockfile' do
    lockfile = new_lockfile
    lockfile.write_lockfile
    expect(File.exist?(path)).to be true
    lockfile.remove_lockfile
    expect(File.exist?(path)).to be false
  end

  it 'returns lockfile info correctly' do
    lockfile = new_lockfile
    expect(lockfile.info).to eql({ pid: nil, program_name: '' })
    lockfile.write_lockfile
    expect(lockfile.info['pid']).to be_an(Integer)
    expect(lockfile.info['program_name']).to be_a(String)
    File.delete(path)
    expect(lockfile.info).to eql({ pid: nil, program_name: '' })
  end

  it 'does not overwrite the lockfile' do
    lockfile = new_lockfile
    lockfile.write_lockfile
    expect { lockfile.write_lockfile }.to raise_error('Cannot acquire lock. Lockfile already exists.')
  end

  it 'will raise an error if a lock tries to be deleted more than once' do
    # An error here will alert us to the fact
    # that locks are are not behaving correctly.
    lockfile = new_lockfile
    lockfile.write_lockfile
    lockfile.remove_lockfile
    expect { lockfile.remove_lockfile }.to raise_error('Cannot delete Lockfile. Does not exist.')
  end

  it 'removes the lock if validate_command fails' do
    lockfile = new_lockfile
    bogus_body = {
      pid:          555,
      program_name: 'test',
    }
    File.write(path, bogus_body.to_json)
    expect(lockfile.already_running?).to be(false)
    expect(lockfile.lockfile_exists?).to be(false)
  end

  context 'checks if the process id is already running' do
    it 'with a current lock' do
      lockfile = new_lockfile
      allow(lockfile).to receive(:validate_command).and_return('validate_command')
      lockfile.write_lockfile
      # Ensure that we are calling validate_command rather than returning false.
      expect(lockfile.already_running?).to eql('validate_command')
    end
    it 'without a current lock' do
      lockfile = new_lockfile
      expect(lockfile.already_running?).to be(false)
    end
  end
end
