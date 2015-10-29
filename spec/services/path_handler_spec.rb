require 'rails_helper'

describe PathHandler do
 let(:result) { 'config/integrations' }
 subject { PathHandler.new.default_config_path }

  specify 'default_config_path returns right result' do
    expect(subject).to eq result
   end
end