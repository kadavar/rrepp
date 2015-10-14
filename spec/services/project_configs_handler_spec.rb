require 'rails_helper'

describe ProjectConfigsHandler do
  include UsesTempFiles

  let(:config) { build :config, :issues_and_custom_fields }
  let(:file_content) do
    content = config.attributes
    content['jira_custom_fields'] = { 'field' => 'field' }
    content['jira_issue_types'] = { 'bug' => 1 }
    content.to_yaml
  end

  before { allow_any_instance_of(PathHandler).to receive(:default_config_path) { 'tmp' } }

  describe '#synchronize' do
    context 'new config file' do
      in_directory_with_file('non_empty_config.yml')

      before { content_for_file(file_content) }
      before { ProjectConfigsHandler.new.synchronize }

      specify 'creates config in db' do
        expect(Project::Config.count).to eq 1
      end
    end

    context 'with config in db' do
      in_directory_with_file

      before do
        create :config, :issues_and_custom_fields

        ProjectConfigsHandler.new.synchronize
      end

      specify 'creates config file' do
        expect(File.exist?(Rails.root.join 'tmp/test_config.yml')).to be true
      end
    end
  end

  describe '#update_config_file' do
    let(:config_reader) { ProjectConfigsReader.new }

    subject { config_reader.load_config(Rails.root.join 'tmp/test_config.yml')['retry_count'] }

    context 'updates existing file' do
      in_directory_with_file('non_empty_config.yml')

      before { content_for_file(file_content) }
      before { ProjectConfigsHandler.new.synchronize }

      before do
        conf = Project::Config.first
        conf.retry_count = '6'
        conf.save

        attributes = conf.attributes
        attributes[:old_name] = conf.name

        ProjectConfigsHandler.new.update_config_file attributes
      end

      specify 'updates config file' do
        is_expected.to eq 6
      end
    end
  end
end
