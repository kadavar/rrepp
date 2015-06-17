class ProjectsHandler
  class << self
    def perform
      update_redis_projects
      create_or_update_projects
      update_project_params
    end

    private

    def redis_projects
      ThorHelpers::Redis.projects
    end

    def parsed_projects
      JSON.parse(redis_projects, { quirks_mode: true })
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
        config = Project::Config.find_by(name: params['config_path'].split('/').last.gsub('.yml', ''))

        project.update_attributes(pid: params['pid'], last_update: params['last_update'], config: config)
      end
    end

    def update_project_params
      Project.find_each { |project| project.update_attributes(online: process_exists?(project.pid)) }
    end

    def process_exists?(pid)
      begin
        Process.kill(0, pid)
      rescue Errno::ESRCH # "No such process"
        return false
      rescue Errno::EPERM # "Operation not permitted"
        # at least the process exists
        return true
      rescue TypeError # If nil
        return false
      else
        return true
      end
    end
  end
end
