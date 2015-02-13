module Jira2Pivotal
  class Bridge < Base

    def initialize(config_file, project_name)
      @config = Config.new(config_file, project_name)
    end

    def jira
      @jira ||= Jira2Pivotal::Jira::Project.new(@config)
    end

    def pivotal
      @pivotal ||= Jira2Pivotal::Pivotal::Project.new(@config)
    end

    def sync!
      from_jira_to_pivotal!
      from_pivotal_to_jira!
    end

    def from_pivotal_to_jira!
      # Make connection with Jira

      # Get all stories for the project from Pivotal Tracker
      puts "Getting all stories from #{@config['tracker_project_id']}"

      stories = pivotal.unsynchronized_stories

      puts 'Find Stories: ', stories[:to_create].count + stories[:to_update].count
      puts 'Start uploading to Jira'

      import_counter = jira.create_tasks!(stories[:to_create])
      update_counter = jira.update_tasks!(stories[:to_update])

      puts "Successfully imported #{import_counter} and updated #{update_counter} stories in Jira"
    end

    def from_jira_to_pivotal!
      # Make connection with Pivotal Tracker

      # Get all issues for the project from JIRA
      puts "Getting all the issues for #{@config['jira_project']}"

      issues = jira.unsynchronized_issues

      puts 'Find Issues: ', issues.count
      puts 'Start uploading to Pivotal Tracker'

      import_counter = pivotal.create_tasks!(issues[:to_create])
      update_counter = pivotal.update_tasks!(issues[:to_update])

      puts "Successfully imported #{import_counter} and updated #{update_counter} issues into Pivotal Tracker"
    end
  end
end
