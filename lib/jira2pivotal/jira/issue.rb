module Jira2Pivotal
  module Jira
    class Issue < Base

      attr_accessor :issue, :project

      def initialize(project, issue=nil)
        @project = project
        @issue = issue
      end

      def comments
        @comments ||= issue.comments.map { |comment| comment unless comment.body =~ Regexp.new(comment_text) }.compact
      end

      def attachments
        @attachments ||= issue.attachments.map { |attachment| Attachment.new(project, attachment) }
      end

      def add_marker_comment(story_url)
        # Add comment to the original JIRA issue
        puts 'Adding a comment to the JIRA issue'
        comment = issue.comments.build
        comment.save( :body => "#{comment_text}: #{story_url}" )
      end

      def key
        issue.key
      end

      def to_pivotal
        story_args = {
            name:           issue.summary,
            current_state:  issue_status_to_story_state,
            requested_by:   project.config['tracker_requester'],
            description:    issue.description,
            story_type:     issue_type_to_story_type
        }

        if issue_type_to_story_type == 'feature'
          story_args['estimate'] = 1
        end

        if issue_status_to_story_state == 'accepted'
          last_accepted = nil
          issue.changelog['histories'].each do |history|
            history['items'].each do |change|

              if change['to'] == issue.status.id
                last_accepted = history['created']
              end
            end
          end

          if last_accepted
            story_args['accepted_at'] = last_accepted
          end
        end

        story_args
      end

      def issue_status_to_story_state
        status_map = {
            '1'     => 'unstarted',
            '3'     => 'started',
            '4'     => 'rejected',
            '10001' => 'delivered',
            '10008' => 'accepted',
            '5'     => 'delivered',
            '6'     => 'accepted',
            '400'   => 'finished',
            '401'   => 'finished'
        }

        status_map[issue.status.id]
      end

      def issue_type_to_story_type
        type_map = {
            '1'   => 'bug',
            '2'   => 'feature',
            '3'   => 'feature',
            '4'   => 'feature',
            '5'   => 'feature',
            '6'   => 'feature',
            '7'   => 'feature',
            '8'   => 'feature',
            '9'   => 'feature',
            '10'  => 'feature'
        }

        type_map[issue.issuetype.id]
      end

      def comment_text
        'A Pivotal Tracker story has been created for this Issue'
      end
    end
  end
end
