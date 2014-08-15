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
    end
  end

end
