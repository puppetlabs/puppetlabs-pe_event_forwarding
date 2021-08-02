require 'spec_helper_local'
require_relative '../../../../files/util/processor'
require 'open3'
require 'find'
require 'tempfile'

describe CommonEvents::Processor do
  subject(:processor) { described_class.new(path) }

  let(:path)           { '/tmp/blah/processors.d/proc1.sh' }
  let(:procs_dir)      { '/tmp/blah/processors.d' }
  let(:temp_file_path) { '/tmp/proc1-temp-file' }

  let(:invoke_result) do
    return 'stdout_message', 'stderr_message', 0
  end

  before(:each) do
    f = instance_double(File)
    allow(f).to receive(:write)
    allow(f).to receive(:flush)
    allow(f).to receive(:path).and_return(temp_file_path)
    allow(Tempfile).to receive(:create).and_yield(f)
    allow(Open3).to receive(:capture3).with("#{path} #{temp_file_path}").and_return(invoke_result)
  end

  context '#find_each' do
    context 'processors directory exists' do
      before(:each) do
        allow(File).to receive(:exist?).with(procs_dir).and_return(true)
      end

      context 'processors in the directory' do
        before(:each) do
          allow(Find).to receive(:find).with(procs_dir).and_return(procs_paths)
        end

        it 'returns correct number of processors' do
          expect(described_class.find_each(procs_dir).count).to eq(4)
        end

        it 'returns correct object types' do
          described_class.find_each(procs_dir) do |yielded_processor|
            expect(yielded_processor.class).to be(described_class)
          end
        end
      end

      context 'no processors present' do
        before(:each) do
          allow(Find).to receive(:find).with(procs_dir).and_return([])
        end

        it 'returns no processors' do
          expect(described_class.find_each(procs_dir).count).to eq(0)
        end
      end
    end
  end

  context '.initialize' do
    it 'has full path property' do
      expect(processor.path).to eq(path)
    end

    it 'has correct name property' do
      expect(processor.name).to eq('proc1.sh')
    end
  end

  context '.invoke' do
    before(:each) { processor.invoke(events_data) }

    it 'populates stdout' do
      expect(processor.stdout).to eq('stdout_message')
    end

    it 'populates stderr' do
      expect(processor.stderr).to eq('stderr_message')
    end

    it 'populates exit code' do
      expect(processor.status).to eq(0)
    end
  end
end
