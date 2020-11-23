require_relative '../../../lib/common_events_library/util/pe_http'

describe 'PE Http' do
  it 'fails without a username/password or token' do
    expect { PeHttp.new('my_hostname') }.to raise_error(ArgumentError, 'Must specify username and password or token.')
    expect { PeHttp.new('my_hostname', username: 'admin') }.to raise_error(ArgumentError, 'Must specify username and password or token.')
    expect { PeHttp.new('my_hostname', password: 'pie') }.to raise_error(ArgumentError, 'Must specify username and password or token.')
  end

  it 'does not generate a token if one is already provided' do
    expect(PeHttp.new('my_hostname', token: 'my_token')).not_to receive(:get_pe_token)
  end

  it 'generates the correct auth header' do
    pe_client = PeHttp.new('my_hostname', token: 'my_token')
    expect(pe_client.pe_auth_header).to eq('X-Authentication' => 'my_token')
  end

  it 'resets the port after fetching a token' do
    response = { 'body' => 'the response body' }
    allow(response).to receive(:body).and_return(response['body'].to_json)
    allow_any_instance_of(PeHttp).to receive(:post_request).and_return(response)
    pe_client = PeHttp.new('my_hostname', port: 8000, username: 'admin', password: 'pie')
    expect(pe_client.port).to eq(8000)
    expect(pe_client.get_pe_token).to eq(nil)
  end
end
