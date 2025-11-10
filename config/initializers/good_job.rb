Rails.application.configure do
  # Configure GoodJob
  config.good_job.execution_mode = :external
  config.good_job.queues = "*"
  config.good_job.max_threads = 5
  config.good_job.poll_interval = 30 # seconds
  config.good_job.shutdown_timeout = 25 # seconds
  config.good_job.enable_cron = true

  # Scheduled jobs (cron-style)
  config.good_job.cron = {
    # Sync WaniKani data for all users every 6 hours
    wanikani_sync: {
      cron: "0 */6 * * *", # Every 6 hours at minute 0
      class: "WanikaniSyncAllUsersJob",
      description: "Sync WaniKani data for all configured users"
    },
    # Sync Renshuu data for all users every 6 hours (offset by 3 hours)
    renshuu_sync: {
      cron: "0 3-21/6 * * *", # Every 6 hours at minute 0, starting at 3am
      class: "RenshuuSyncAllUsersJob",
      description: "Sync Renshuu data for all configured users"
    }
  }

  # Enable dashboard in development
  config.good_job.dashboard_default_locale = :en
end
