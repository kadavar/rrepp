class ThorHelpers::Redis < ThorHelpers::Base
  class << self
    def insert_config(config, hash)
      params_to_redis(config, hash)
    end

    def update_project(project_name)
      new_projects =
        if parsed_projets.present?
          cleaned_projects(project_name).merge(project_data(project_name))
        else
          project_data(project_name)
        end

      projects_to_redis(new_projects)
    end

    def last_update(project_name, time)
      if parsed_projets.present?
        pid = parsed_projets[project_name]['pid']
        projects = cleaned_projects(project_name).merge(project_data(project_name, pid, time))

        projects_to_redis(projects)
      else
        false
      end
    end

    def projects
      Sidekiq.redis { |connection| connection.get('projects') }
    end

    def projects_to_redis(projects)
      Sidekiq.redis { |connection| connection.set('projects', projects.to_json) }
    end

    private

    def params_to_redis(params, random_hash)
      Sidekiq.redis { |connection| connection.set(random_hash, encrypt_params(params, random_hash)) }
    end

    def encrypt_params(params, random_hash)
      crypt = ActiveSupport::MessageEncryptor.new(random_hash)
      crypt.encrypt_and_sign(params.to_json)
    end

    def project_data(project_name, pid=Process.pid,  last_update=Time.now.utc)
      { project_name => { 'pid' => pid, 'last_update' => last_update } }
    end

    def parsed_projets
      JSON.parse(projects, { quirks_mode: true })
    end

    def cleaned_projects(project_name)
      parsed_projets.reject { |k,v| k == project_name }
    end
  end
end
