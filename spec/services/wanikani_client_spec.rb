require 'rails_helper'

RSpec.describe WanikaniClient do
  let(:api_key) { '0a8fdb36-99df-4f29-96c2-efe6a810c88b' }
  let(:client) { described_class.new(api_key) }

  describe '#get_user' do
    it 'fetches user information', :vcr do
      result = client.get_user

      expect(result).to be_a(Hash)
      expect(result['object']).to eq('user')
      expect(result['data']).to be_present
    end
  end

  describe '#get_study_materials' do
    it 'fetches study materials', :vcr do
      result = client.get_study_materials

      expect(result).to be_a(Hash)
      expect(result['object']).to eq('collection')
      expect(result['data']).to be_an(Array)
    end
  end

  describe '#get_subjects' do
    it 'fetches subjects', :vcr do
      result = client.get_subjects(levels: '1')

      expect(result).to be_a(Hash)
      expect(result['object']).to eq('collection')
      expect(result['data']).to be_an(Array)
    end
  end

  describe 'error handling' do
    let(:invalid_client) { described_class.new('invalid_key') }

    it 'raises AuthenticationError for invalid API key' do
      expect {
        invalid_client.get_user
      }.to raise_error(WanikaniClient::AuthenticationError)
    end
  end
end
