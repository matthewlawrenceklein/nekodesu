class RenshuuSyncAllUsersJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info("Starting Renshuu sync for all users")

    User.find_each do |user|
      next unless user.renshuu_configured?

      RenshuuSyncJob.perform_later(user.id)
    end

    Rails.logger.info("Queued Renshuu sync jobs for all configured users")
  end
end
