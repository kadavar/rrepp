class JiraToPivotal::Pivotal::Project < JiraToPivotal::Pivotal::Base
  attr_accessor :config
  attr_reader :project, :client

  def initialize(config)
    @config = config

    build_project
    @config.delete('tracker_token')
  end

  def build_project
    retries ||= @config['script_repeat_time'].to_i
    @client = TrackerApi::Client.new(token: config['tracker_token'])
    @project  = client.project(config['tracker_project_id'])

  rescue => error
    retry unless (retries -= 1).zero?

    logger.error_log(error)
    Airbrake.notify_or_ignore(
      error,
      parameters: { config: @config },
      cgi_data: ENV.to_hash
      )

    raise error
  end

  def update_config(options)
    @config.merge!(options)
  end

  # TODO: Rewrite using new gem classes
  def create_story(story_args)
  end

  def unsynchronized_stories
    load_unsynchronized_stories
  end

  # TODO: Rewrite using new gem classes
  def create_tasks!(issues, options)
    # Copy attachments
    # Copy notes
    # Create connection between Jira and Pivotal
  end

  # TODO: Rewrite using new gem classes
  def update_tasks!(issues)
  end

  def select_task(stories, issue)
    stories.find { |story| story.external_id == issue.key }
  end

  def map_users_by_email
    retries ||= @config['script_repeat_time'].to_i
    project.memberships.map(&:person).map { |member| { member.name => member.email } }.reduce Hash.new, :merge
  rescue => error
    sleep(1) && retry unless (retries -= 1).zero?
    raise error
  end

  private

  def load_unsynchronized_stories
    { to_create: load_to_create_stories, to_update: load_to_update_stories }
  end

  def load_to_create_stories
    usefull_stories.select { |story| (story.integration_id.nil? || story_ends_with_nil?(story)) }.map { |story| JiraToPivotal::Pivotal::Story.new(project, story, @config) }
  end

  def load_to_update_stories
    usefull_stories.select { |story| (!story.integration_id.nil? && !story_ends_with_nil?(story)) }.map { |story| JiraToPivotal::Pivotal::Story.new(project, story, @config) }
  end

  def story_ends_with_nil?(story)
    story.external_id.present? ? story.external_id.split('-').last == '0' : true
  end

  def usefull_stories
    project.stories(filter: 'story_type:bug,chore,feature state:unstarted,started,finished,delivered,rejected')
  end

  def find_stories_by(attrs={})
    @project.stories(attrs)
  end
end
