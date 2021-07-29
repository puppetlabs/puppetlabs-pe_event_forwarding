require 'spec_helper'
require_relative '../../../../files/util/index'

describe CommonEvents::Index do
  subject(:index) { described_class.new(statedir) }

  let(:statedir)   { 'blah' }
  let(:index_type) { 'foo' }
  let(:filepath)   { "#{statedir}/common_events_indexes.yaml" }

  before(:each) do
    allow(File).to receive(:exist?).with(filepath).and_return(true)
    allow(File).to receive(:read).and_return(index_yaml)
  end

  context '.initialize' do
    context 'file does not already exist' do
      before(:each) do
        allow(File).to receive(:exist?).with(filepath).and_return(false)
      end

      it 'creates a new file with correct content' do
        expect(File).to receive(:write).with(filepath, index_yaml)
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

  context '.new_index_file' do
    before(:each) { allow(File).to receive(:write) }
    it 'creates the correct file' do
      expect(File).to receive(:write).with(filepath, index_yaml)
      index.new_index_file
    end

    it 'sets current count to zero' do
      index.new_index_file
      expect(index.counts).to eq(index_data)
    end
  end

  context '.counts' do
    context '@counts variable does not exist yet' do
      it 'retrieves current count' do
        expect(index.counts).to eq(index_data)
      end
    end
    context '@counts variable exists' do
      before(:each) do
        index.instance_variable_set(:@counts, index_data)
      end

      it 'retrieves current count' do
        expect(File).not_to receive(:read)
        expect(index.counts).to eq(index_data)
      end

      it 'reads file when refresh is true' do
        expect(index.counts(refresh: true)).to eq(index_data)
      end
    end
  end

  context '.save' do
    it 'writes correct yaml' do
      expect(File).to receive(:write).with(filepath, index_yaml(foo: 10))
      index.save(foo: 10)
    end

    it 'updates @counts' do
      expect(File).to receive(:write).with(filepath, index_yaml(foo: 10))
      expect(File).to receive(:read).once
      index.save(foo: 10)
      expect(index.count(:foo)).to eq(10)
    end
  end
end
