require 'rails_helper'

describe JiraToPivotal::ScriptLogger do
  let(:logger) { JiraToPivotal::ScriptLogger.instance }
  let(:config) { { 'option1' => '1' } }

  context 'update config' do
    before do
      logger.config = config
      logger.update_config('option2' => '2')
    end

    specify 'updates config' do
      expect(logger.config.key? 'option2').to be true
    end
  end
end
