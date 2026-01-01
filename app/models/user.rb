class User < ApplicationRecord
  has_many :wani_subjects, dependent: :destroy
  has_many :renshuu_items, dependent: :destroy
  has_many :anki_vocabs, dependent: :destroy
  has_many :dialogues, dependent: :destroy
  has_many :dialogue_attempts, dependent: :destroy

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  validates :speech_speed, numericality: { greater_than: 0.25, less_than_or_equal_to: 4.0 }, allow_nil: true

  def wanikani_configured?
    wanikani_api_key.present?
  end

  def renshuu_configured?
    renshuu_api_key.present?
  end

  def openrouter_configured?
    openrouter_api_key.present?
  end

  def openai_configured?
    openai_api_key.present?
  end
end
