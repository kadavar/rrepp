require 'rails_helper'
include JiraToPivotal::Retryable
include JiraToPivotal::ErrorsHandler

describe JiraToPivotal::Retryable do
  let(:config) { { 'retry_count' => 1, 'repeat_delay' => 0 } }
  let(:logger) { double }
  before { allow(config).to receive(:airbrake_message_parameters).and_return(config)}
  before { allow(logger).to receive(:error_log).with(any_args).and_return(true) }

  context 'with TrackerApi::Error' do
    specify 'skips airbrake notification' do
      expect(Airbrake).to receive(:notify_or_ignore).exactly(0).times

      retryable { fail(TrackerApi::Error, instance_double('error', response: 'message')) }
    end
  end
end
