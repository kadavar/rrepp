require 'hashie/mash'

class SettingsLoader < Hashie::Mash
  def load!
    self.deep_merge! settings_from_file('settings.yml')
  #  self.deep_merge! settings_from_file('settings.local.yml')
    self
  end

  private


  def settings_from_file(filename)
    file_path       = Rails.root.join 'config', filename
    file_contents   = File.read(file_path)
    parsed_file     = ERB.new(file_contents).result
    loaded_settings = YAML.load(parsed_file)

    {}.tap do |settings|
      if loaded_settings
        settings.deep_merge! loaded_settings['global'] || {}
        settings.deep_merge! loaded_settings[Rails.env] || {}
      end
    end
  rescue Errno::ENOENT # File not found error
    {}
  end
end