class User < ApplicationRecord
  has_many :wani_subjects, dependent: :destroy
  has_many :dialogues, dependent: :destroy
  has_many :dialogue_attempts, dependent: :destroy

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true

  def wanikani_configured?
    wanikani_api_key.present?
  end

  def openrouter_configured?
    openrouter_api_key.present?
  end
end
