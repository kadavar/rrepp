JIRA::RequestClient.class_eval
  # Returns the response if the request was successful (HTTP::2xx) and
  # raises a JIRA::HTTPError if it was not successful, with the response
  # attached.

  def request(*args)
    retries ||= 5
    response = make_request(*args)
    raise HTTPError.new(response) unless response.kind_of?(Net::HTTPSuccess)
    response
  rescue => error
    sleep(1) && retry unless (retries -= 1).zero?
    raise error
  end
end
