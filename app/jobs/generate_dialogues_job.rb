class GenerateDialoguesJob < ApplicationJob
  queue_as :default

  retry_on DialogueGenerationService::GenerationError, wait: 5.minutes, attempts: 3
  retry_on OpenrouterClient::ApiError, wait: 1.hour, attempts: 3

  def perform(user_id, count: 10, difficulty_level: "beginner")
    user = User.find(user_id)

    unless user.openrouter_configured?
      Rails.logger.warn("User #{user_id} does not have OpenRouter configured")
      return
    end

    Rails.logger.info("Generating #{count} #{difficulty_level} dialogues for user #{user_id}")

    successful = 0
    failed = 0

    count.times do |i|
      begin
        service = DialogueGenerationService.new(user, difficulty_level: difficulty_level)
        dialogue = service.generate

        successful += 1
        Rails.logger.info("Generated dialogue #{i + 1}/#{count}: #{dialogue.id}")
      rescue DialogueGenerationService::GenerationError => e
        failed += 1
        Rails.logger.error("Failed to generate dialogue #{i + 1}/#{count}: #{e.message}")
      end

      # Small delay between generations to avoid rate limits
      sleep(2) if i < count - 1
    end

    Rails.logger.info(
      "Completed dialogue generation for user #{user_id}: #{successful} successful, #{failed} failed"
    )
  end
end
