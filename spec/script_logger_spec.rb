require 'rails_helper'

describe JiraToPivotal::ScriptLogger do
  let(:config) do
    { 'option1' => '1', 'log_file_name' => 'log', 'sync_action' => 'INVOICED' }
  end
  let(:logger) { JiraToPivotal::ScriptLogger.new(config) }

  describe '#formatter' do
    subject { logger.instance_variable_get(:@logger).info 'info' }
    context 'when sync_action is not INVOICED' do
      it { is_expected.to be true }
    end

    context 'when sync_action is not INVOICED' do
      let(:config) do
        { 'option1' => '1', 'log_file_name' => 'log', 'sync_action' => 'nan' }
      end
      it { is_expected.to be true }
    end

  end

  describe '#update config' do
    before do
      logger.config = config
      logger.update_config('option2' => '2')
    end

    specify 'updates config' do
      expect(logger.config.key? 'option2').to be true
    end
  end

  describe '#jira_logger' do
    subject { logger.jira_logger.config }
    it { is_expected.to eq config }
  end

  describe '#attrs_log' do
    let(:attrs) { 'attrs' }
    subject { logger.attrs_log(attrs) }
    it { is_expected.to be true }
  end

  describe '#error_log' do
    let(:e) { Exception.new('message') }
    subject { logger.error_log(e) }

    context 'when not jira or not tracker error' do
      it { is_expected.to eq true }
    end

    context 'when exception is jira_http error' do
      let(:e) { JIRA::HTTPError.new('message') }
      it { is_expected.to eq true }
    end
  end
end
