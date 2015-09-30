require 'rails_helper'

describe JiraToPivotal::ScriptLogger do
  let(:config) { { 'option1' => '1', 'log_file_name' => 'log' } }
  let(:logger) { JiraToPivotal::ScriptLogger.new(config) }

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
