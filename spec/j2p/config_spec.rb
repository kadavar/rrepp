require 'rails_helper'

describe JiraToPivotal::Config do

  let(:config) { { somekey:'somekey', custom_fields: 'custom fields', ownership_handler: 'ownership_handler' } }
  subject (:j2p_conf) { JiraToPivotal::Config.new(config) }
  describe '#[]' do
    context 'when key is not exist ' do
      let(:key) { 'not_exist' }
      it { expect(j2p_conf.[](key)).to eq nil }
    end

    context 'when key is exist' do
      let(:key) { :somekey }
      it { expect(j2p_conf.[](key)).to eq 'somekey' }
    end
  end

  describe '#airbrake_message_parameters' do
    context 'when return except hash' do
      let(:result) { { somekey: 'somekey' } }
      it { expect(j2p_conf.airbrake_message_parameters).to eql result }
    end
  end
end
