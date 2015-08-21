require 'rails_helper'
include JiraToPivotal::Retryable

describe JiraToPivotal::Retryable do
  context 'with TrackerApi::Error' do
    specify 'skips airbrake notification' do
      expect(Airbrake).to receive(:notify_or_ignore).exactly(0).times
      
      retryable { fail(TrackerApi::Error, instance_double('error', response: 'message')) }
    end
  end
end
