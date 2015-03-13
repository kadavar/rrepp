class JiraToPivotal::Pivotal::Project < JiraToPivotal::Pivotal::Base

  attr_accessor :config

  def initialize(config)
    @config = config

    build_project
    @config.delete('tracker_token')
  end

  def build_project
    PivotalTracker::Client.token = config['tracker_token']
    @project = PivotalTracker::Project.find(config['tracker_project_id'])

  rescue => error
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

  def create_story(story_args)
    story = @project.stories.create(story_args)
    if story.errors.empty?
      JiraToPivotal::Pivotal::Story.new(@project, story)
    else
      puts "Can't create Pivotal Story: #{story.errors.errors.uniq.join(', ')}"
      nil
    end
  end

  def unsynchronized_stories
    load_unsynchronized_stories
  end

  def create_tasks!(issues, options)
    @options = options
    counter =  0

    issues.each do |issue|
      putc '.'
      story = create_story(issue.to_pivotal)

      if story.present?
        # note_text = ''
        #
        # if issue.issuetype == '6'
        #   note_text = 'This was an epic from JIRA.'
        # end
        #
        # # Don't create comment with src, we use straight integration
        # #note_text += "\n\nSubmitted through Jira\n#{@config['jira_uri_scheme']}://#{@config['jira_host']}/browse/#{issue.key}"
        #
        # story.notes.create(text: note_text) unless note_text.blank?

        # Add notes to the story
        puts 'Checking for comments'

        story.create_notes!(issue)

        # Add attachments to the story
        issue.attachments.each do |attachment|
          attachment.download
          story.upload_attachment(attachment.to_path)
        end

        # issue.add_marker_comment(story.url)
        story.assign_to_jira_issue(issue.key, @config.jira_url) #we should assign jira task only at the and to prevent recending comments and attaches back
        issue.assign_to_pivotal_issue(story.url, @config.merge!(@options)) #we should add pivotal url to JIRA issue

        counter += 1
      end
    end

    return counter
  end

  def update_tasks!(issues)
    counter =  0

    pivotal_stories = find_stories_by(integration:'Jira')

    issues.each do |issue|
      putc '.'

      pivotal_story = select_task(pivotal_stories, issue)
      story = Story.new(@project, pivotal_story)

      puts 'Updates for comments'
      story.create_notes!(issue)

      counter += 1
    end

    return counter
  end

  def select_task(stories, issue)
    stories.find { |story| story.jira_url == "#{@config.jira_url}/browse/#{issue.key}" }
  end

  def map_users_by_email
    @project.memberships.all.map { |member|  { member.name => member.email } }.reduce Hash.new, :merge
  end

  private

  def load_unsynchronized_stories
    { to_create: load_to_create_stories, to_update: load_to_update_stories }
  end

  # TODO Refactor 2 methods below
  def load_to_create_stories
    usefull_stories.select { |story| (story.jira_url.nil? || story_ends_with_nil?(story)) }.map { |story| JiraToPivotal::Pivotal::Story.new(@project, story, @config) }
  end

  def load_to_update_stories
    usefull_stories.select { |story| (!story.jira_url.nil? && !story_ends_with_nil?(story)) }.map { |story| JiraToPivotal::Pivotal::Story.new(@project, story, @config) }
  end

  def story_ends_with_nil?(story)
    story.jira_url.present? ? story.jira_url.split('/').last == 'nil' : true
  end

  def usefull_stories
    @project.stories.all(story_type: %w(bug chore feature), state: %w(unstarted started finished delivered rejected))
  end

  def find_stories_by(attrs={})
    @project.stories.all(attrs)
  end
end
