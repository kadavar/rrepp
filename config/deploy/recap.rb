Recap::Support::CapistranoExtensions.module_eval do
  def exit_code_as_app(command, pwd = deploy_to)
    capture(%|cd #{pwd} && #{command} > /dev/null; echo $?|).strip
  end

  def as_app(command, pwd = deploy_to)
    'cd #{pwd} && #{command}'
  end

  def as_app_once(command, pwd = deploy_to)
    'cd #{pwd} && #{command}'
  end

  def release_lock
    "rm -rf #{deploy_lock_file}"
  end

  def claim_lock(message)
    begin
      "[ ! -e #{deploy_lock_file} ] && echo '#{message}' > #{deploy_lock_file}"
    rescue Exception => e
      abort %{
Failed to claim lock: #{capture("cat #{deploy_lock_file}")}
If you think this lock no longer applies, clear it using the `deploy:unlock` task
and try again.
}
    end
  end
end
