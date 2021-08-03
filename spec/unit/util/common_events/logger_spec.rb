require_relative '../../../../files/util/logger'

describe CommonEvents::Logger do
  subject(:io_logger) { described_class.new(io) }

  let(:io) { StringIO.new }
  let(:json_io) { JSON.parse(io.string) }

  context '.info' do
    it 'has correct default source' do
      io_logger.info('blah')
      expect(json_io['source']).to eql('common_events')
    end

    it 'has correct custom source' do
      io_logger.info('test msg', source: 'test_src')
      expect(json_io['source']).to eql('test_src')
    end

    it 'has correct message' do
      io_logger.info('test msg')
      expect(json_io['message']).to eql('test msg')
    end

    it 'has correct exit_code' do
      io_logger.info('test msg', exit_code: 2)
      expect(json_io['exit_code']).to be(2)
    end

    it 'has correct severity (INFO)' do
      io_logger.info('test msg')
      expect(json_io['severity']).to eql('INFO')
    end
  end

  context '.fatal' do
    it 'has correct default source' do
      io_logger.fatal('blah')
      expect(json_io['source']).to eql('common_events')
    end

    it 'has correct custom source' do
      io_logger.fatal('test msg', source: 'test_src')
      expect(json_io['source']).to eql('test_src')
    end

    it 'has correct message' do
      io_logger.fatal('test msg')
      expect(json_io['message']).to eql('test msg')
    end

    it 'has correct exit_code' do
      io_logger.fatal('test msg', exit_code: 2)
      expect(json_io['exit_code']).to be(2)
    end

    it 'has correct severity (FATAL)' do
      io_logger.fatal('fatal message')
      expect(json_io['severity']).to eql('FATAL')
    end
  end

  context '.warn' do
    it 'has correct default source' do
      io_logger.warn('blah')
      expect(json_io['source']).to eql('common_events')
    end

    it 'has correct custom source' do
      io_logger.warn('test msg', source: 'test_src')
      expect(json_io['source']).to eql('test_src')
    end

    it 'has correct message' do
      io_logger.warn('test msg')
      expect(json_io['message']).to eql('test msg')
    end

    it 'has correct exit_code' do
      io_logger.warn('test msg', exit_code: 2)
      expect(json_io['exit_code']).to be(2)
    end

    it 'has correct severity (WARN)' do
      io_logger.warn('fatal message')
      expect(json_io['severity']).to eql('WARN')
    end
  end
end
