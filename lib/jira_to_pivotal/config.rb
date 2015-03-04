class JiraToPivotal::Config < JiraToPivotal::Base

  def initialize(config)
    @config = config
  end

  def [](key)
    @config[key]
  end

  def jira_url
    "#{@config['jira_uri_scheme']}://#{@config['jira_host']}"
  end

  def merge!(attrs)
    @config.merge!(attrs)
  end

  def delete(attrs)
    @config.delete(attrs)
  end
end
