class RenshuuSyncJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)

    unless user.renshuu_configured?
      Rails.logger.info("Skipping Renshuu sync for user #{user_id} - no API key configured")
      return
    end

    Rails.logger.info("Starting Renshuu sync for user #{user_id}")
    service = RenshuuSyncService.new(user)
    service.sync_all
    Rails.logger.info("Completed Renshuu sync for user #{user_id}")
  rescue StandardError => e
    Rails.logger.error("Renshuu sync failed for user #{user_id}: #{e.message}")
    raise
  end
end
