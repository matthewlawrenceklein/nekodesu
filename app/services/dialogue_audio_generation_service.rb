class DialogueAudioGenerationService
  class GenerationError < StandardError; end

  include DialoguesHelper

  def initialize(dialogue)
    @dialogue = dialogue
    @tts_client = OpenaiTtsClient.new
  end

  def generate
    dialogue_lines = parse_dialogue_lines(@dialogue.japanese_text)
    audio_files_data = []

    dialogue_lines.each_with_index do |line, index|
      next unless line[:speaker] && line[:text]

      voice = character_tts_voice(line[:speaker])
      instructions = character_tts_instructions(line[:speaker])

      begin
        audio_data = @tts_client.generate_speech(
          text: line[:text],
          voice: voice,
          instructions: instructions
        )

        audio_blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new(audio_data),
          filename: "dialogue_#{@dialogue.id}_line_#{index}.mp3",
          content_type: "audio/mpeg"
        )

        audio_files_data << {
          line_index: index,
          speaker: line[:speaker],
          text: line[:text],
          audio_key: audio_blob.key,
          voice: voice,
          generated_at: Time.current.iso8601
        }

        Rails.logger.info("Generated audio for dialogue #{@dialogue.id}, line #{index}: #{line[:speaker]}")
      rescue OpenaiTtsClient::ApiError => e
        Rails.logger.error("Failed to generate audio for dialogue #{@dialogue.id}, line #{index}: #{e.message}")
        raise GenerationError, "Failed to generate audio: #{e.message}"
      end
    end

    @dialogue.update!(audio_files: audio_files_data)
    @dialogue
  end
end
