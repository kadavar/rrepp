class SynchronizationDispatchWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  recurrence { hourly.minute_of_hour(0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55) }

  def perform
    projects_to_sync = Project.projects_to_sync.pluck(:id)

    projects_to_sync.each do |project|
      job_id = SyncWorker.perform_async(project)
    end
  end
end
