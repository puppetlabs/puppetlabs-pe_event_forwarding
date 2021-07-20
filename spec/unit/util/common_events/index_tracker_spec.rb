require_relative '../../../../files/lib/util/common_events_index'

describe CommonEvents::Index do
  subject(:index) { described_class.new(statedir, index_type) }

  let(:statedir)   { 'blah' }
  let(:index_type) { 'foo' }
  let(:filepath)   { "#{statedir}/common_events_indexes.yaml" }
  let(:yaml) do
    <<~YAML
      ---
      foo: 10
    YAML
  end

  before(:each) do
    allow(File).to receive(:exist?).with(filepath).and_return(true)
    allow(File).to receive(:read).and_return(yaml)
  end

  context '.initialize' do
    context 'file does not already exist' do
      before(:each) do
        allow(File).to receive(:exist?).with(filepath).and_return(false)
      end

      it 'creates a new file with correct content' do
        expect(File).to receive(:write).with(filepath, "---\nfoo: 0\n")
        index
      end
    end

    context 'file does exist' do
      it 'creates a new file with correct content' do
        expect(File).not_to receive(:write)
        index
      end
    end
  end

  context '.create_new_index_file' do
    before(:each) { allow(File).to receive(:write) }
    it 'creates the correct file' do
      expect(File).to receive(:write).with(filepath, "---\nfoo: 0\n")
      index.create_new_index_file
    end

    it 'sets current count to zero' do
      index.create_new_index_file
      expect(index.count).to be(0)
    end
  end

  context '.count' do
    it 'retreives current count' do
      index.instance_variable_set(:@count, 5)
      expect(index.count).to be(5)
    end
  end

  context '.read_count' do
    context 'with valid yaml' do
      it 'retreives correct count' do
        expect(index.read_count).to be(10)
      end
    end

    context 'with invalid yaml' do
      let(:yaml) do
        <<~YAML
          example:
            - 'foo'
            bar: 'baz'
        YAML
      end

      it 'throw an error for invalid yaml' do
        expect { index.read_count }.to raise_error(Psych::SyntaxError)
      end
    end
  end

  context '.save_latest_index' do
    before(:each) do
      allow(File).to receive(:read).and_return({ 'foo' => 15 }.to_yaml)
    end

    it 'writes correct yaml' do
      expect(File).to receive(:write).with(filepath, yaml)
      index.save_latest_index(10)
    end
  end
end
