class WanikaniSyncAllUsersJob < ApplicationJob
  queue_as :default

  def perform
    users_with_wanikani = User.where.not(wanikani_api_key: nil)

    Rails.logger.info("Starting WaniKani sync for #{users_with_wanikani.count} users")

    users_with_wanikani.find_each do |user|
      WanikaniSyncJob.perform_later(user.id)
    end

    Rails.logger.info("Queued WaniKani sync jobs for all users")
  end
end
