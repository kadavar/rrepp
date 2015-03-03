module Jira2Pivotal
  module Loggs
    class Base < ::Jira2Pivotal::Base
      def jira_pivotal_connection_for_log(story, issue)
        "#{story.story.url} >> #{jira_url}/browse/#{issue.issue.key}"
      end

      def jira_url
        "#{@config['jira_uri_scheme']}://#{@config['jira_host']}"
      end
    end
  end
end
