require 'rails_helper'

describe JiraToPivotal::Jira::Base do
  let(:base) { JiraToPivotal::Jira::Base.new }
  let(:task) { double 'task' }
  let(:error) { RuntimeError }
  describe '#create_tasks!' do
    it { expect{ base.create_tasks!(task) }.to raise_error(error) }
  end

  describe '#create_tasks!' do
    it { expect{ base.update_tasks!(task) }.to raise_error(error) }
  end

  describe '#create_notes!' do
    it { expect{ base.create_notes!(task) }.to raise_error(error) }
  end

  describe '#select_task' do
    let(:task_array) { double 'task_array' }
    let(:related_array) { double 'related_task' }
    it { expect{ base.select_task(task_array,related_array) }.to raise_error(error) }
  end
end