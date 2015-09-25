module JiraToPivotal
  class Bridge < JiraToPivotal::Base
    attr_reader :config

    def initialize(hash)
      @config = JiraToPivotal::Config.new(decrypt_config(hash))
    end

    def jira
      @jira ||= JiraToPivotal::Jira::Project.new(config)
    end

    def pivotal
      @pivotal ||= JiraToPivotal::Pivotal::Project.new(config)
    end

    def ownership_handler
      @ownership_handler ||= JiraToPivotal::Jira::OwnershipHandler.new(jira, pivotal, config)
    end

    def sync!
      binding.pry
      ThorHelpers::Redis.last_update(@config['project_name'], Time.zone.now)
      pivotal.update_config(ownership_handler: ownership_handler)

      return unless jira.project && pivotal

      logger.update_config(options)
      retryable(can_fail: true, try: 1) do
        pivotal.update_config(ownership_handler: ownership_handler)

        connect_jira_to_pivotal!
        # Right now flow jira -> pivotal is disabled
        # from_jira_to_pivotal!
        from_pivotal_to_jira!
      end
    end

    def connect_jira_to_pivotal!
      jira.update_tasks!(pivotal.unsynchronized_stories[:to_update])

      stories = pivotal.unsynchronized_stories[:to_create]
      issues = jira.unsynchronized_issues[:to_update]

      pivotal_jira_connection(issues, stories)
    end

    def from_pivotal_to_jira!
      # Make connection with Jira

      # Get all stories for the project from Pivotal Tracker
      jira.update_tasks!(pivotal.unsynchronized_stories[:to_update])

      # After update issues and stories grep pivotal stories again
      # because some of them might be updated
      stories = pivotal.unsynchronized_stories

      jira.create_sub_task_for_invoiced_issues!(stories[:to_create])
      jira.create_tasks!(stories[:to_create])
    end

    def from_jira_to_pivotal!
      # Make connection with Pivotal Tracker

      pivotal.create_tasks!(jira.unsynchronized_issues[:to_create], options)
      # Not finished yet
      # Need more clarification
      # pivotal.update_tasks!(issues[:to_update])
    end

    def options
      {
        custom_fields: jira.issue_custom_fields
      }
    end

    private

    def decrypt_config(hash)
      crypt = ActiveSupport::MessageEncryptor.new(hash)

      encrypted_data = Sidekiq.redis { |connection| connection.get(hash) }
      decrypted_back = crypt.decrypt_and_verify(encrypted_data)

      JSON.parse(decrypted_back)
    end

    def pivotal_jira_connection(issues, stories)
      mapped_issues = map_issues_by_pivotal_url(issues).reduce({}, :merge)

      stories_to_update(mapped_issues, stories).each do |key, value|
        issue = issues.find  { |local_issue| local_issue.key == key }
        story = stories.find { |local_story| local_story.url == value }

        next unless story.assign_to_jira_issue(issue.issue.key, jira.url)

        logger.jira_logger.update_jira_pivotal_connection_log(key, value)
      end
    end

    def stories_to_update(mapped_issues, stories)
      result = {}
      stories.each do |story|
        next if mapped_issues[story.story.url].nil?

        result[mapped_issues[story.story.url]] = story.story.url if story.jira_issue_id != mapped_issues[story.story.url]
      end
      result
    end

    def map_issues_by_pivotal_url(issues)
      pivotal_url_id = options[:custom_fields].key(@config['jira_custom_fields']['pivotal_url'])
      issues.map { |issue| { issue.issue.send(pivotal_url_id) => issue.issue.key } }
    end
  end
end
