class ProjectLogsController < BaseController
  require 'find'

  def index
    @project_logs = project_logs_collection
  end

  def show
    @log_name = params[:name]
    @log_text = Kaminari.paginate_array(log_text).page(params[:page]).per(10)
  end

  private

  def project_logs_collection
    Find.find(Rails.root.join('log')).select { |p| /.*\.log$/ =~ p }.map { |path| path.split('/').last.gsub('.log', '') }
  end

  def log_text
    temp_text = ''
    text = []
    File.foreach(Rails.root.join('log', "#{params[:name]}.log")) do |line|
      current_line = line.uncolorize

      if current_line =~ line_regex
        text << temp_text if temp_text.present?
        temp_text = ''
        temp_text += current_line
      else
        temp_text += current_line
      end
    end
    text.reverse

  rescue Errno::ENOENT
    []
  end

  def line_regex
    # Match [2015-04-13 18:01:48.363616 UTC #1111 P#Project_name]
    /^\[\d{4}\-\d{2}\-\d{2}\ \d{2}\:\d{2}\:\d{2}\.\d+\ \w+\ \#\d+ P\#\w+\]/
  end
end
