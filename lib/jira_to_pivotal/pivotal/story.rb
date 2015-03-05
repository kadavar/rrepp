class JiraToPivotal::Pivotal::Story < JiraToPivotal::Pivotal::Base

  attr_accessor :project, :story

  def initialize(project, story=nil, config=nil)
    @project = project
    @story = story
    @config = config
  end

  def notes
    @note ||= story.notes.all
  end

  def add_note(args)
    story.notes.create(args)
  end

  def create_notes!(issue)
    issue.comments.each do |comment|
      begin     #TODO wtf?
        add_note( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
      rescue Exception => e
        add_note( author: comment.author['displayName'], text: "*Real Author: #{comment.author['displayName']}*\n\n#{comment.body}", noted_at: comment.created)
      end
    end
  end

  def upload_attachment(filepath)
    story.upload_attachment(filepath)
  end

  def url
    story.url
  end

  def assign_to_jira_issue(key, url)
    story.update(jira_id: key, jira_url: url)
  end

  def to_jira(custom_fields)
    description = replace_image_tag

    attrs =
    {
      'summary'      => story.name,
      'description'  => description.to_s,
      'issuetype'    => { 'id' => story_type_to_issue_type },
    }
    attrs['timetracking'] = { 'originalEstimate' => "#{make_estimate_positive}h" } if set_original_estimate?
    attrs.merge!(custom_fields_attrs(custom_fields))
  end

  def replace_image_tag
    story.description.gsub(regexp_for_image_tag_replace, '!\1!')
  end

  def regexp_for_image_tag_replace
    #Match ![some_title](http://some.site.com/some_imge.png)
    /\!\[\w*\]\(([\w\p{P}\p{S}]+)\)/u
  end

  def make_estimate_positive
    estimate = story.estimate.to_i
    estimate < 0 ? 0 : estimate
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
    attrs[pivotal_points_id] = make_estimate_positive unless is_bug? || is_chore?
    attrs
  end

  def story_type_to_issue_type
    type_map = {
        'bug'     => '1',
        'feature' => '2',
        'chore'   => '10005'
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
      'delivered' => 'Resolve Issue',
      'rejected'  => 'Reopen Issue'
    }

    status_map[story.current_state]
  end

  def jira_issue_id
    if story.jira_id.present? || story.jira_url.present?
      story.jira_id || story.jira_url.split('/').last
    else
      nil
    end
  end

  def unstarted?
    story.current_state == 'unstarted'
  end

  def started?
    story.current_state == 'started'
  end

  def is_chore?
    story.story_type == 'chore'
  end

  def is_bug?
    story.story_type == 'bug'
  end

  def set_original_estimate?
    (unstarted? || started?) && !(is_bug? || is_chore?)
  end
end

PivotalTracker::Story.class_eval do
  def to_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.story {
        xml.name "#{name}"
        xml.description "#{description}"
        xml.story_type "#{story_type}"
        xml.estimate "#{estimate}"
        xml.current_state "#{current_state}"
        xml.requested_by "#{requested_by}"
        xml.owned_by "#{owned_by}"
        xml.labels "#{labels}"
        xml.project_id "#{project_id}"

        xml.jira_id "#{jira_id}" if jira_id
        xml.jira_url "#{jira_url}" if jira_url
        xml.other_id "#{other_id}" if other_id
        xml.integration_id "#{integration_id}" if integration_id
        xml.created_at DateTime.parse(created_at.to_s).to_s if created_at
        xml.accepted_at DateTime.parse(accepted_at.to_s).to_s if accepted_at
        xml.deadline DateTime.parse(deadline.to_s).to_s if deadline
      }
    end
    return builder.to_xml
  end
end
