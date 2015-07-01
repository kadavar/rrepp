class JiraToPivotal::Pivotal::Story < JiraToPivotal::Pivotal::Base

  attr_accessor :project, :story, :config

  def initialize(project, story=nil, config=nil)
    @project    = project
    @story      = story
    @config     = config
  end

  def ownership_handler
    @config[:ownership_handler]
  end

  # TODO: Rewrite using new gem classes
  def notes
    retries ||= @config['script_repeat_time'].to_i
    @note   ||= story.comments
  rescue => error
    sleep(1) && retry unless (retries -= 1).zero?
    Airbrake.notify_or_ignore(error, parameters: @config.for_airbrake, cgi_data: ENV.to_hash)
    false
  end

  def url
    story.url
  end

  # Temporary method untill we update all project to use new gem
  def assign_to_jira_issue(key, jira_url)
    retries ||= @config['script_repeat_time'].to_i

    story = project.story(story.id)

    if jira_url.nil?
      # Make keys like 'ProjectName-0' when delete old integrations
      story.external_id = key.split('-').first + '-0'
    else
      integrations = project.client.get("/projects/#{config['tracker_project_id']}/integrations").body
      integration_match = integrations.select { |int| int['base_url'] == jira_url.gsub(":#{config.port}",'') }[0]

      if integration_match
        story.integration_id = integration_match['id']
        story.external_id = key
      else
        logger.attrs_log(integrations, 'integrations')
        raise RuntimeError, 'something wrong with integrations'
      end
    end

    story.save

  rescue Exception => error
    sleep(1) && retry unless (retries -= 1).zero?
    Airbrake.notify_or_ignore(error, parameters: @config.for_airbrake, cgi_data: ENV.to_hash)
    false
  end

  def to_jira(custom_fields)
    main_attrs.merge!(original_estimate_attrs)
              .merge!(custom_fields_attrs(custom_fields))
              .merge!(ownership_handler.reporter_and_asignee_attrs(self))
  rescue Exception => error
    Airbrake.notify_or_ignore(error, parameters: @config.for_airbrake, cgi_data: ENV.to_hash)
    false
  end


  def regexp_for_image_tag_replace
    #Match ![some_title](http://some.site.com/some_imge.png)
    /\!\[\w*\]\(([\w\p{P}\p{S}]+)\)/u
  end

  def custom_fields_attrs(custom_fields)
    attrs = Hash.new
    # Custom fields in Jira
    # Set Name in config.yml file
    pivotal_url    = @config['jira_custom_fields']['pivotal_url']
    pivotal_points = @config['jira_custom_fields']['pivotal_points']

    pivotal_url_id    = custom_fields.key(pivotal_url)
    pivotal_points_id = custom_fields.key(pivotal_points)

    attrs[pivotal_url_id]    = story.url              if pivotal_url.present?
    attrs[pivotal_points_id] = story.estimate.to_i    unless bug? || chore? || empty_estimate?
    attrs
  end

  def story_type_to_issue_type
    type_map = {
        'bug'     => @config['jira_issue_types']['bug'].to_s,
        'feature' => @config['jira_issue_types']['feature'].to_s,
        'chore'   => @config['jira_issue_types']['chore'].to_s
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
    # When estimate not set, pivotal return -1
    story.estimate.to_i == -1
  end

  def original_estimate_attrs
    set_original_estimate? ? { 'timetracking' => { 'originalEstimate' => "#{make_estimate_positive}h" } } : {}
  end

  def main_attrs
    {
      'summary'      => story.name.squish.truncate(255, separator: ' ', omission: ''),
      'description'  => description_with_replaced_image_tag.to_s,
      'issuetype'    => { 'id' => story_type_to_issue_type },
    }
  end

  def description_with_replaced_image_tag
    story.description.gsub(regexp_for_image_tag_replace, '!\1!')
  end
end
