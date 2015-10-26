require 'rails_helper'
include JiraProjectsHelper

describe JiraToPivotal::Jira::OwnershipHandler do
  let(:pivotal) { instance_double('pivotal',
                  :map_users_by_email => { 'email_address' => 'examp@examp',
                                           'owner1_name' => 'name@s' }) }
  let(:jira) { instance_double('jira',
               :jira_assignable_users => { 'email_address' =>
                                          { 'examp@examp' => 'exampl@examp' },
                                           'display_name' =>
                                          { 'owner1_name' => 'owner1_name' } }) }
  let(:owner_1) { instance_double('owner', name: 'owner1_name') }
  let(:owner_2) { instance_double('owner', name: 'name2') }
  let(:story) { double 'story' }
  let(:config) { { 'script_repeat_time' => '5m', 'repeat_delay' => 0 } }
  let!(:handler) { JiraToPivotal::Jira::OwnershipHandler.new(jira, pivotal, config) }

  describe '#reporter_and_asignee_attrs' do
    subject(:attrs) { handler.reporter_and_asignee_attrs(story) }

    context 'raise an TrackerApi::Error' do
      before { allow(story).to receive(:owners) { fail(TrackerApi::Error, instance_double('error', response: 'message')) } }
      before { allow(config).to receive(:airbrake_message_parameters) { 'params' } }
      before { allow(handler).to receive(:airbrake_report_and_log) { true } }
      it { is_expected.to eql Hash.new }
    end

    context 'raise an JIRA::HTTPError' do
      before { allow(story).to receive(:owners) { fail(JIRA::HTTPError, instance_double('error', message: 'message')) } }
      it 'fail' do
        expect { attrs }.to raise_exception(JIRA::HTTPError)
      end
    end

    context 'when there are no owners' do
      before { allow(story).to receive(:owners) { [] } }
      it { is_expected.to eql Hash.new }
    end

    context 'when   name_by_full_name and name_by_email is present' do
      let(:result) {
        { "reporter" => { "name" => owner_1.name },
          "assignee" => { "name" => owner_1.name }
        }
      }
      it { is_expected.to eql result }
      it 'use first owner' do
        expect(attrs['reporter']["name"]).to eq(owner_1.name)
      end
    end

    context 'when name_by_full_name doens`t` present' do
      let(:jira) { instance_double('jira',
                  jira_assignable_users: { 'email_address' =>
                                          { 'examp@emailkey' => 'exampemail@email' },
                                           'display_name' =>
                                          { nil => '' } }) }
      let(:pivotal) { instance_double('pivotal',
                      map_users_by_email: { 'email_addres' => 'examp@exemail',
                                            owner_1.name => 'ex@lda' }) }
      let(:result) {
        { "reporter" => { "name" => "exampemail@email" },
          "assignee" => { "name" => "exampemail@email" }
        }
      }
      it { is_expected.to eql result }
    end
  end
end
