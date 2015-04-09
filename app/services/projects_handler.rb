class ProjectsHandler
  class << self
    def perform
      update_redis_projects
      create_or_update_projects
    end

    private

    def redis_projects
      ThorHelpers::Redis.projects
    end

    def parsed_projects
      JSON.parse(redis_projects, {quirks_mode: true})
    end

    def projects
      parsed_projects.present? ? parsed_projects : {}
    end

    def update_redis_projects
      new_projects = Hash.new

      projects.each do |project_name, params|
        new_projects.merge!(project_name => params) if process_exists?(params['pid'])
      end

      ThorHelpers::Redis.projects_to_redis(new_projects.presence)
    end

    def create_or_update_projects
      projects.each do |project_name, params|
        project = Project.find_or_create_by(name: project_name)
        project.update_attributes(pid: params['pid'], last_update: params['last_update'])
      end
    end

    def process_exists?(pid)
      begin
        Process.kill(0, pid)
      rescue Errno::ESRCH # "No such process"
        return false
      rescue Errno::EPERM # "Operation not permitted"
        # at least the process exists
        return true
      else
        return true
      end
    end
  end
end
