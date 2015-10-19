class ProjectConfigsHandler
  def initialize
    @reader = ProjectConfigsReader.new
    @writer = ProjectConfigsWriter.new
    @composer = ConfigComposer.new
    @path = PathHandler.new
  end

  def synchronize
    pull_from_config_folder
    push_to_config_folder
  end

  def update_config_file(attributes)
    load_and_update_config(attributes)
  end

  private

  def pull_from_config_folder
    @path.list_of_config_names.each { |name| load_or_create_config(name) }
  end

  def push_to_config_folder
    db_configs = @composer.list_of_config_names
    file_configs = @path.list_of_config_names

    (db_configs - file_configs).each { |name| create_config_file(name) }
  end

  def load_or_create_config(name)
    config_params = @reader.load_config(@path.config_path(name))

    @composer.update_or_create(config_params, name)

  rescue Exception => e
    # TODO: Add errors handler to show them on frontend
    Airbrake.notify_or_ignore(e, cgi_data: ENV.to_hash)
    false
  end

  def create_config_file(name)
    path = @path.config_path(name)

    return true if File.readable?(path)

    config_hash = @composer.config(name)

    @writer.write_config(path, config_hash)

  rescue Exception => e
    # TODO: Add errors handler to show them on frontend
    Airbrake.notify_or_ignore(e, cgi_data: ENV.to_hash)
    false
  end

  def load_and_update_config(attributes)
    path = @path.config_path(attributes[:old_name])

    data = @reader.load_config(path)

    attributes.except(:old_name, :new_name).each { |key, value| data[key] = value }

    @writer.update(data, attributes[:new_name].present?, path, @path.config_path(attributes[:new_name]))
  end
end
