module JiraToPivotal
  module Pivotal
    class Story < Pivotal::Base
      delegate :url, to: :story
      delegate :client, to: :story

      attr_reader :project, :story, :config

      def initialize(project, story = nil, config = nil)
        @project    = project
        @story      = story
        @config     = config
      end

      def ownership_handler
        config[:ownership_handler]
      end

      # TODO: Rewrite using new gem classes
      def notes
        retryable do
          @notes ||= story.comments
        end
      end

      # TODO: Temporary method until gem would be updated
      def assign_to_jira_issue(key, jira_url)
        story = project.story(self.story.id)
        integrations, integration = select_integration(project, jira_url)

        options =
          {
            integration: integration,
            story: story,
            key: key
          }

        if integration.present?
          update_integration(options)
        else
          logger.attrs_log(integrations, 'integrations')
          fail 'something wrong with integrations'
        end

      rescue => error
        airbrake_report_and_log(error, parameters: config.airbrake_message_parameters)
      end

      # TODO: Temporary method until gem would be updated
      def update_integration(options = {})
        story = options[:story]

        if options[:key].nil?
          # Make keys like '0' when delete old integrations
          story.external_id = '0'
        else
          story.integration_id = options[:integration]['id']
          story.external_id = options[:key]
        end

        story.save
      end

      # TODO: Temporary method until gem would be updated
      def select_integration(project, jira_url)
        integrations = project.client.get("/projects/#{config['tracker_project_id']}/integrations").body
        integration = integrations.select { |int| int['base_url'] == jira_url.gsub(":#{config.port}", '') }[0]

        [integrations, integration]
      end

      def to_jira(custom_fields)
        retryable do
          main_attrs.merge!(original_estimate_attrs).
            merge!(custom_fields_attrs(custom_fields)).
            merge!(ownership_handler.reporter_and_asignee_attrs(story))
        end
      end

      def regexp_for_image_tag_replace
        # Matches:
        # ![some title](http://some.site.com/some_imge.png)
        # ![some title](http://some.site.com/some_imge.png "some alt")
        /\!\[\w+ *\w+\]\(([\w\p{P}\p{S}]+) *\"*\w* *\w*\"*\)/u
      end

      def custom_fields_attrs(custom_fields)
        attrs = {}
        # Custom fields in Jira
        # Set Name in config.yml file
        pivotal_url    = config['jira_custom_fields']['pivotal_url']
        pivotal_points = config['jira_custom_fields']['pivotal_points']

        pivotal_url_id    = custom_fields.key(pivotal_url)
        pivotal_points_id = custom_fields.key(pivotal_points)

        attrs[pivotal_url_id]    = story.url              if pivotal_url.present?
        attrs[pivotal_points_id] = story.estimate.to_i    unless bug? || chore? || empty_estimate?
        attrs
      end

      def story_type_to_issue_type
        type_map =
          {
            'bug'     => config['jira_issue_types']['bug'].to_s,
            'feature' => config['jira_issue_types']['feature'].to_s,
            'chore'   => config['jira_issue_types']['chore'].to_s
          }

        type_map[story.story_type]
      end

      def current_story_status_to_issue_status
        status_map = {
          'started'   => 'In Progress',
          'unstarted' => 'Open',
          'finished'  => 'In Progress',
          'delivered' => 'Resolved',
          'rejected'  => 'Reopened'
        }

        status_map[story.current_state]
      end

      def story_status_to_issue_status
        status_map = {
          'started'   => 'Start Progress',
          'unstarted' => 'Stop Progress',
          'finished'  => 'Do nothing',
          'delivered' => 'Resolve Issue',
          'rejected'  => 'Reopen Issue'
        }

        status_map[story.current_state]
      end

      def jira_issue_id
        story.external_id
      end

      def unstarted?
        story.current_state == 'unstarted'
      end

      def started?
        story.current_state == 'started'
      end

      def chore?
        story.story_type == 'chore'
      end

      def bug?
        story.story_type == 'bug'
      end

      def set_original_estimate?
        (unstarted? || started?) && !(bug? || chore?) && !empty_estimate?
      end

      def empty_estimate?
        # When estimate is not set, pivotal returns -1
        story.estimate.to_i == -1
      end

      def original_estimate_attrs
        set_original_estimate? ? { 'timetracking' => { 'originalEstimate' => "#{story.estimate.to_i}h" } } : {}
      end

      def main_attrs
        {
          'summary'      => story.name.squish.truncate(255, separator: ' ', omission: ''),
          'description'  => description_with_replaced_image_tag.to_s,
          'issuetype'    => { 'id' => story_type_to_issue_type }
        }
      end

      def description_with_replaced_image_tag
        # Gem returns nil if description is empty
        story.description.to_s.gsub(regexp_for_image_tag_replace, '!\1!')
      end
    end
  end
end
