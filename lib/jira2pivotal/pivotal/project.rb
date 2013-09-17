module Jira2Pivotal
  module Pivotal
    class Project < Base

      def initialize(config)
        @config = config

        PivotalTracker::Client.token = @config['tracker_token']
        @project = PivotalTracker::Project.find(@config['tracker_project_id'])
      end

      def create_story(story_args)
        @project.stories.create(story_args)
      end

    end
  end

end
