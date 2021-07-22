require_relative '../../../../files/util/http'

describe CommonEvents::Http do
  it 'fails without a hostname' do
    expect { described_class.new }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1)')
  end

  it 'does not prepend https if already present' do
    expect(described_class.new('https://my_hostname').hostname).to eq('https://my_hostname')
  end

  it 'makes pagination params correctly' do
    expect(described_class.make_params('orchestrator/v1/jobs', limit: 5, offset: 2)).to eq('orchestrator/v1/jobs?limit=5&offset=2')
    expect(described_class.make_params('orchestrator/v1/jobs', limit: nil, offset: 2)).to eq('orchestrator/v1/jobs?offset=2')
    expect(described_class.make_params('orchestrator/v1/jobs', limit: 5, offset: nil)).to eq('orchestrator/v1/jobs?limit=5')
    expect(described_class.make_params('orchestrator/v1/jobs', limit: nil, offset: nil)).to eq('orchestrator/v1/jobs?')
  end

  it 'can convert a response to a hash' do
    response = { property: 'value' }.to_json
    allow(response).to receive(:body).and_return(response)
    expect(described_class.response_to_hash(response)['property']).to eq('value')
  end
end
