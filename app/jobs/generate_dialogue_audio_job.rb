class GenerateDialogueAudioJob < ApplicationJob
  queue_as :default

  retry_on DialogueAudioGenerationService::GenerationError, wait: 5.minutes, attempts: 3
  retry_on OpenaiTtsClient::ApiError, wait: 1.hour, attempts: 3

  def perform(dialogue_id)
    dialogue = Dialogue.find(dialogue_id)

    Rails.logger.info("Generating audio for dialogue #{dialogue_id}")

    service = DialogueAudioGenerationService.new(dialogue)
    service.generate

    Rails.logger.info("Successfully generated audio for dialogue #{dialogue_id}")
  rescue DialogueAudioGenerationService::GenerationError => e
    Rails.logger.error("Failed to generate audio for dialogue #{dialogue_id}: #{e.message}")
    raise
  end
end
