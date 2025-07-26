RSpec.shared_context 'api response' do
  let(:parsed_response) { JSON.parse(response.body) }
end

