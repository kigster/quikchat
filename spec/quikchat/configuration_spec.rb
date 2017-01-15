require 'quikchat/configuration'

RSpec.describe QuikChat::Configuration do
  subject { QuikChat::Configuration.new }

  describe '#adapter' do
    it 'returns the adapter' do
      adapter = double("adapter")
      subject.adapter = adapter
      expect(subject.adapter).to eq(adapter)
    end
  end

  describe '#adapter=' do
    let(:adapter) { double }

    after do
      subject.adapter = nil
    end

    it 'sets the adapter on the configuration' do
      subject.adapter = adapter
      expect(subject.adapter).to eq(adapter)
    end
  end

  describe '#quikchat_url' do
    let(:host_url) { 'http://localhost:3000' }

    it 'returns the quikchat_url' do
      subject.quikchat_url = host_url
      expect(subject.quikchat_url).to eq(host_url)
    end
  end

  describe '#quikchat_url=' do
    let(:host_url) { 'http://localhost:3000' }

    it 'sets the adapter on the configuration' do
      subject.quikchat_url = host_url
      expect(subject.quikchat_url).to eq(host_url)
    end
  end
end
