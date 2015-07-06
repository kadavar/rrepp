class JiraToPivotal::Jira::Issue < JiraToPivotal::Jira::Base
  attr_accessor :issue, :project

  def initialize(options={})
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
    puts 'Adding a comment to the JIRA issue'
    comment = issue.comments.build
    comment.save( body: "#{comment_text}: #{story_url}" )
  end

  def build_comment
    issue.comments.build
  end

  def key
    issue.key
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
    # Remove pivotal_points field if type Bug or Sub-task
    # Becouse issues with Bug and Sub-task type doesn't have this field
    # And it cause an error while request
    # Also remove issue-type for sub-task because it can't be changed
    if original_estimate?(attrs) || ((bug? || subtask? || chore?) && attrs['fields']['timetracking'].present?)
      attrs['fields'].except!('timetracking')
    end

    if (bug? || subtask? || chore?)
      pivotal_story_points = config[:custom_fields].key(config['jira_custom_fields']['story_points'])
      attrs['fields'].except!(pivotal_story_points)
      attrs['fields'].except!('issuetype') if subtask?
    end

    remove_fields_without_permission(attrs)
  end

  def remove_fields_without_permission(attrs)
    attrs['fields'].except!('reporter') unless user_permissions.modify_reporter?
  end

  def original_estimate?(attrs)
    unless issue.fields == attrs['fields']
      issue.fields['timetracking'].present? ? issue.fields['timetracking']['originalEstimate'] : nil
    end
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

  def update_status!(story)
    # Jira give only several status options to select
    # So if we try to change status that not in list
    # Status would not change
    if can_change_status?(story) && !subtask?
      response = set_issue_status!(args_for_change_status(story))
    else
      false
    end
    # TODO Rewrite this change status logic with state machine gem.
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
          comment.save({ 'body' => "#{note.author} added a comment in Pivotal Tracker:: \n\n #{note.text} \n View this Pivotal Tracker story: #{story.url}" })
        end
      rescue Exception => e
        logger.error_log(e)
        Airbrake.notify_or_ignore(e, cgi_data: ENV.to_hash)
      end
    end
  end

  def assign_to_pivotal_issue(story_url, config)
    pivotal_url_id = config[:custom_fields].key(config['jira_custom_fields']['pivotal_tracker_url'])
    attributes = { 'fields' =>  { pivotal_url_id => story_url } }

    save!(attributes, config)
  end

  private

  # TODO: Refactor this(use gem logic to make request or something else)
  def set_issue_status!(args)
    http_method = :post

    @client.send(http_method, transitions_api_url, args.to_json)
  end

  # TODO: Refactor this(use gem logic to make request or something else)
  def get_available_statuses
    http_method = :get

    response = @client.send(http_method, transitions_api_url)

    hash_of_data = JSON.parse(response.body)
    transitions = hash_of_data['transitions'].map { |t| {t['name'] => t['id']} }.reduce Hash.new, :merge
  end

  def transitions_api_url
    "/rest/api/2/issue/#{issue.id}/transitions"
  end

  def can_change_status?(story)
    get_available_statuses.keys.include?(story.story_status_to_issue_status)
  end

  def args_for_change_status(story)
    args = {'update' => {}, 'transition' => get_available_statuses[story.story_status_to_issue_status] }
  end
end
