require 'rails_helper'

describe NotificationMailer, :type => :mailer do
  before(:each) do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    NotificationMailer.default :from=> 'j2p@examp.com'
  end
  after(:each) do
    ActionMailer::Base.deliveries.clear
  end
  describe '#notification_email' do
    subject { ActionMailer::Base.deliveries.count }
    let(:send_email) { NotificationMailer.send(:new).notification_email('headers','examp@examp.com').deliver }
    context 'when deliveries count change by 1 ' do
      before { send_email }
      it { is_expected.to eq 1 }
     end
  end
end