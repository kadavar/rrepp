module Jira2Pivotal
  module Logger
    class Base < ::Jira2Pivotal::Base
      def jira_pivotal_connection_for_log(story, issue)
        "#{story.story.url} >> #{url}/browse/#{issue.issue.key}"
      end
    end
  end
end
