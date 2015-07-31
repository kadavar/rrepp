require 'rails_helper'

describe JiraToPivotal::Pivotal::Story do
  let!(:pivotal_story) { JiraToPivotal::Pivotal::Story.new(nil) }
  let(:inner_story) { double 'inner story' }

  before do
    allow(pivotal_story).to receive(:story) { inner_story }
  end

  describe '#to_jira' do
    before do
    end
  end

  describe '#main_attrs' do
    before do
      allow(inner_story).to receive(:name) { 'name' }
    end
  end

  describe '#description_with_replaced_image_tag' do
    subject { pivotal_story.description_with_replaced_image_tag }

    before do
      description = double 'description'
      allow(description).to receive(:to_s) { '![tinyarrow](https://sourceforge.net/images/icon_linux.gif "tiny arrow")' }

      allow(inner_story).to receive(:description) { description }

      allow(pivotal_story).to receive (:regexp_for_image_tag_replace) { /\!\[\w*\]\(([\w\p{P}\p{S}]+)\)/u }
    end

    it 'returns correct image tag' do
      is_expected.to be false
    end
  end
end
