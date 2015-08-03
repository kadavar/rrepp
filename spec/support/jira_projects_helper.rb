module JiraProjectsHelper
  def generate_jira_issues
    issues = []

    (1..2).each do |counter|
      status =
      if counter.even?
        double 'status', name: 'Invoiced'
      else
        double 'status', name: 'Other'
      end

      current_issue = double 'issue', status: status

      allow(current_issue).to receive(:key) { "id#{counter}" }

      issues << current_issue
    end

    issues
  end
end
