module JiraToPivotal
  module Jira
    class Issue < Base
      attr_accessor :issue, :project, :config

      delegate :key, to: :issue

      def initialize(options = {})
        @client  = options[:client]
        @project = options[:project]
        @issue   = options[:issue]
        @config  = options[:config]
      end

      def comments
        @comments ||= issue.comments.map { |comment| comment unless comment.body =~ Regexp.new(comment_text) }.compact
      end

      def attachments
        @attachments ||= issue.attachments.map { |attachment| JiraToPivotal::Jira::Attachment.new(project, attachment) }
      end

      def user_permissions
        @user_permissions ||= JiraToPivotal::Jira::UserPermissions.new(@project)
      end

      def add_marker_comment(story_url)
        # Add comment to the original JIRA issue
        comment = issue.comments.build
        comment.save(body: "#{comment_text}: #{story_url}")
      end

      def build_comment
        issue.comments.build
      end

      def save!(attrs, config)
        return false if closed?
        remove_not_saveable_fields(attrs, config)

        begin
          issue.save!(attrs)
        rescue JIRA::HTTPError => e
          logger.attrs_log(attrs)
          logger.error_log(e)

          Airbrake.notify_or_ignore(
            e,
            parameters: config.airbrake_message_parameters.merge(attrs),
            cgi_data: ENV.to_hash,
            error_message: "#{e.response.body}"
          )

          false
        end
      end

      def remove_not_saveable_fields(attrs, config)
        # Remove pivotal_points field if type Bug or Sub-task or Chore
        # Because issues with Bug and Sub-task type doesn't have this field
        # And it cause an error while request
        # Also remove issue-type for sub-task because it can't be changed
        if remove_original_estimate?(attrs)
          attrs['fields'].except!('timetracking')
        end

        if issue_without_points?
          pivotal_story_points = config[:custom_fields].key(config['jira_custom_fields']['pivotal_points'])
          attrs['fields'].except!(pivotal_story_points)
          attrs['fields'].except!('issuetype') if subtask?
        end

        remove_fields_without_permission(attrs)
      end

      def remove_fields_without_permission(attrs)
        attrs['fields'].except!('reporter') unless user_permissions.modify_reporter?
      end

      def issue_without_points?
        bug? || subtask? || chore?
      end

      def remove_original_estimate?(attrs)
        if issue_without_points? || not_equal_fields?(attrs)
          issue.fields['timetracking'] && issue.fields['timetracking']['originalEstimate']
        end
      end

      def not_equal_fields?(attrs)
        issue.fields != attrs['fields']
      end

      def bug?
        issue.fields['issuetype']['name'] == 'Bug'
      end

      def subtask?
        issue.fields['issuetype']['name'] == 'Sub-task'
      end

      def chore?
        issue.fields['issuetype']['name'] == 'Chore'
      end

      def closed?
        if issue.fields['status'].present?
          issue.fields['status']['name'] == 'Closed'
        else
          false
        end
      end

      def to_pivotal
        # Write code when restore Jira -> Pivotal flow
      end

      def issue_status_to_story_state
        status_map =
          {
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
        type_map =
          {
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

      def update_status!(story)
        # Jira give only several status options to select
        # So if we try to change status that not in list
        # Status would not change
        if can_change_status?(story) && !subtask?
          update_issue_status!(args_for_change_status(story))
        else
          false
        end
        # TODO: Rewrite this change status logic with state machine gem.
        # Write results to all posible scenarios
        # For example subtask doen't have In Progress state
      rescue JIRA::HTTPError => e
        logger.error_log(e)
        Airbrake.notify_or_ignore(
          e,
          parameters: args_for_change_status(story),
          cgi_data: ENV.to_hash,
          error_message: "#{e.response.body}"
        )
      end

      def create_notes!(story)
        return false unless story.notes

        story.notes.each do |note|
          begin
            comment = build_comment
            if note.text.present? # pivotal add empty note for attachment
              # TODO: need to grep author here somehow(in new gem we have only person_id attr)
              # TODO: need ability to grep person directly from note
              # HACK: find pivotal project, then membership and then person by person_id
              pivotal_project = story.client.project(config['tracker_project_id'])
              author = pivotal_project.memberships.map(&:person).find { |person| person.id == note.person_id }

              comment.save(
                'body' => "#{author.name} added a comment in Pivotal Tracker::\n\n #{note.text}
                \n View this Pivotal Tracker story: #{story.url}"
              )
            end
          rescue Exception => e
            logger.error_log(e)
            Airbrake.notify_or_ignore(e, parameters: config.airbrake_message_parameters, cgi_data: ENV.to_hash)
          end
        end
      end

      def assign_to_pivotal_issue(story_url, config)
        pivotal_url_id = config[:custom_fields].key(config['jira_custom_fields']['pivotal_url'])
        attributes = { 'fields' =>  { pivotal_url_id => story_url } }

        save!(attributes, config)
      end

      private

      # TODO: Refactor this(use gem logic to make request or something else)
      def update_issue_status!(args)
        http_method = :post

        @client.send(http_method, transitions_api_url, args.to_json)
      end

      # TODO: Refactor this(use gem logic to make request or something else)
      def available_statuses
        http_method = :get

        response = @client.send(http_method, transitions_api_url)

        hash_of_data = JSON.parse(response.body)
        hash_of_data['transitions'].map { |t| { t['name'] => t['id'] } }.reduce({}, :merge)
      end

      def transitions_api_url
        "/rest/api/2/issue/#{issue.id}/transitions"
      end

      def can_change_status?(story)
        available_statuses.keys.include?(story.story_status_to_issue_status)
      end

      def args_for_change_status(story)
        { 'update' => {}, 'transition' => available_statuses[story.story_status_to_issue_status] }
      end
    end
  end
end
