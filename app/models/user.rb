class User < ApplicationRecord
  has_many :wani_subjects, dependent: :destroy
  has_many :wani_study_materials, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }

  def wanikani_configured?
    wanikani_api_key.present?
  end
end
