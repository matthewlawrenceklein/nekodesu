class WanikaniSyncJob < ApplicationJob
  queue_as :default

  retry_on WanikaniClient::RateLimitError, wait: 1.hour, attempts: 3
  retry_on WanikaniClient::ApiError, wait: 5.minutes, attempts: 5

  def perform(user_id)
    user = User.find(user_id)

    unless user.wanikani_configured?
      Rails.logger.warn("User #{user_id} does not have WaniKani configured")
      return
    end

    service = WanikaniSyncService.new(user)
    service.sync_all

    Rails.logger.info("Successfully synced WaniKani data for user #{user_id}")
  rescue WanikaniClient::AuthenticationError => e
    Rails.logger.error("Authentication failed for user #{user_id}: #{e.message}")
    raise
  end
end
