class SynchronizationDispatchWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  #hourly.minute_of_hour(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55)
  recurrence { minutely(1) }

  def perform
    projects_to_sync = Project.projects_to_sync.pluck(:id)

    projects_to_sync.each do |project|
      job_id = SyncWorker.perform_async(project)
    end
  end
end
