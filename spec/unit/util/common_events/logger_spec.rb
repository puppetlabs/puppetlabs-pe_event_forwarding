require_relative '../../../../files/lib/util/logger'

describe CommonEvents::Logger do
  subject(:io_logger) { described_class.new(io) }

  let(:io) { StringIO.new }

  context '.info' do
    it 'has correct default source' do
      io_logger.info('blah')
      expect(JSON.parse(io.string)['source']).to eql('common_events')
    end

    it 'has correct custom source' do
      io_logger.info('test msg', source: 'test_src')
      expect(JSON.parse(io.string)['source']).to eql('test_src')
    end

    it 'has correct message' do
      io_logger.info('test msg')
      expect(JSON.parse(io.string)['message']).to eql('test msg')
    end

    it 'has correct severity (INFO)' do
      io_logger.info('test msg')
      expect(JSON.parse(io.string)['severity']).to eql('INFO')
    end
  end

  context '.fatal' do
    it 'has correct default source' do
      io_logger.fatal('blah')
      expect(JSON.parse(io.string)['source']).to eql('common_events')
    end

    it 'has correct custom source' do
      io_logger.fatal('test msg', source: 'test_src')
      expect(JSON.parse(io.string)['source']).to eql('test_src')
    end

    it 'has correct message' do
      io_logger.fatal('test msg')
      expect(JSON.parse(io.string)['message']).to eql('test msg')
    end

    it 'has correct severity (FATAL)' do
      io_logger.fatal('fatal message')
      expect(JSON.parse(io.string)['severity']).to eql('FATAL')
    end
  end

  context '.warn' do
    it 'has correct default source' do
      io_logger.warn('blah')
      expect(JSON.parse(io.string)['source']).to eql('common_events')
    end

    it 'has correct custom source' do
      io_logger.warn('test msg', source: 'test_src')
      expect(JSON.parse(io.string)['source']).to eql('test_src')
    end

    it 'has correct message' do
      io_logger.warn('test msg')
      expect(JSON.parse(io.string)['message']).to eql('test msg')
    end

    it 'has correct severity (WARN)' do
      io_logger.warn('fatal message')
      expect(JSON.parse(io.string)['severity']).to eql('WARN')
    end
  end
end
