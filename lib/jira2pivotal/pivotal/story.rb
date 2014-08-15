module Jira2Pivotal
  module Pivotal
    class Story < Base

      attr_accessor :project, :story

      def initialize(project, story=nil)
        @project = project
        @story = story
      end

      def add_note(args)
        story.notes.create(args)
      end

      def upload_attachment(filepath)
        story.upload_attachment(filepath)
      end

      def url
        story.url
      end

      def assign_to_jira_issue(key, url)
        story.update(jira_id: key, jira_url: url)
      end
    end
  end

end

PivotalTracker::Story.class_eval do


  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.story {
        xml.name "#{name}"
        xml.description "#{description}"
        xml.story_type "#{story_type}"
        xml.estimate "#{estimate}"
        xml.current_state "#{current_state}"
        xml.requested_by "#{requested_by}"
        xml.owned_by "#{owned_by}"
        xml.labels "#{labels}"
        xml.project_id "#{project_id}"

        xml.jira_id "#{jira_id}" if jira_id
        xml.jira_url "#{jira_url}" if jira_url
        xml.other_id "#{other_id}" if other_id
        xml.integration_id "#{integration_id}" if integration_id
        xml.created_at DateTime.parse(created_at.to_s).to_s if created_at
        xml.accepted_at DateTime.parse(accepted_at.to_s).to_s if accepted_at
        xml.deadline DateTime.parse(deadline.to_s).to_s if deadline
      }
    end
    return builder.to_xml
  end
end
