require 'rails_helper'

describe NotificationService do
  let(:monitoring_hash) { { 'test' => { 'pid' => '99999999', 'emails' => ['example@example.com'] } } }

  describe '#check_and_notify' do
    subject(:notify) { NotificationService.check_and_notify(monitoring_hash) }

    before { allow(NotificationMailer).to receive(:delay) { double notification_email: nil } }
    before { allow(Sidekiq).to receive(:redis) { nil } }

    context 'with process' do
      before do
        pid = fork { loop { sleep(1) } }

        monitoring_hash['test']['pid'] = pid
      end

      specify 'emails not sent' do
        expect(NotificationMailer).to receive(:delay).exactly(0).times

        notify
      end

      after { Process.kill('KILL', monitoring_hash['test']['pid'].to_i) }
    end

    context 'without process' do
      specify 'sends notifications' do
        expect(NotificationMailer).to receive(:delay).exactly(1).times

        notify
      end
    end
  end
end
