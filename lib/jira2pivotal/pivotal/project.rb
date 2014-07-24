module Jira2Pivotal
  module Pivotal
    class Project < Base

      attr_accessor :config

      def initialize(config)
        @config = config

        build_project
      end

      def build_project
        PivotalTracker::Client.token = config['tracker_token']
        @project = PivotalTracker::Project.find(config['tracker_project_id'])
      end

      def create_story(story_args)
        Story.new(@project, @project.stories.create(story_args))
      end
    end
  end

end
