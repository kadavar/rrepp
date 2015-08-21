module JiraToPivotal
  module Loggs
    class Base < ::JiraToPivotal::Base
      def jira_pivotal_connection_for_log(story_url, issue_key)
        "#{story_url} >> #{jira_url}/browse/#{issue_key}"
      end

      def jira_url
        "#{@config['jira_uri_scheme']}://#{@config['jira_host']}"
      end
    end
  end
end
