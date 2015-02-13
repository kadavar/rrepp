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

      def build_comment
        issue.comments.build
      end

      def key
        issue.key
      end

      def save!(attrs, config=nil)
        # Remove pivotal_points field if type Bug
        # Becouse issues with Bug type doesn't have this field
        # And it cause an error while request
        if is_bug? && config.present?
          attrs['fields'].except!("customfield_#{config['jira_custom_fields']['pivotal_points']}")
        end

        issue.save! attrs
      end

      def is_bug?
        issue.attrs['fields']['issuetype']['name'] == 'Bug'
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

      def update_status!(client, story)
        @client = client

        # Jira give only several status options to select
        # So if we try to change status that not in list
        # Status would not change
        set_issue_status!(args_for_change_status(story)) if can_change_status?(story)
      end

      def create_notes!(story)
        story.notes.each do |note|
          begin
            comment = build_comment
            if note.text.present? # pivotal add empty note for attachment
              comment.save({ 'body' => "#{note.author} added a comment in Pivotal Tracker:: \n\n #{note.text} \n View this Pivotal Tracker story: #{story.url}" })
            end
          rescue Exception => e
            nil
          end
        end
      end

      private

      # TODO: Refactor this(use gem logic to make request or something else)
      def set_issue_status!(args)
        http_method = :post
        url = "/rest/api/2/issue/#{issue.id}/transitions"

        response = @client.send(http_method, url, args.to_json)
      end

      # TODO: Refactor this(use gem logic to make request or something else)
      def get_available_statuses
        http_method = :get
        url = "/rest/api/2/issue/#{issue.id}/transitions"

        response = @client.send(http_method, url)

        hash_of_data = JSON.parse(response.body)
        transitions = hash_of_data['transitions'].map { |t| {t['name'] => t['id']} }.reduce Hash.new, :merge
      end

      def can_change_status?(story)
        get_available_statuses.keys.include?(story.story_status_to_issue_status)
      end

      def args_for_change_status(story)
        args = {'update' => {}, 'transition' => get_available_statuses[story.story_status_to_issue_status] }
      end
    end
  end
end
