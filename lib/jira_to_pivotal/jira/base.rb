class JiraToPivotal::Jira::Base < ::JiraToPivotal::Base
  def create_tasks!(tasks)
    raise 'Not implemented'
  end

  def update_tasks!(tasks)
    raise 'Not implemented'
  end

  def create_notes!(task)
    raise 'Not implemented'
  end

  def select_task(tasks_array, related_task)
    raise 'Not implemented'
  end
end
