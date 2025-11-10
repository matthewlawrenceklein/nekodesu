class RenshuuItem < ApplicationRecord
  belongs_to :user

  ITEM_TYPES = %w[vocab grammar kanji sentence].freeze

  validates :external_id, presence: true, uniqueness: { scope: :user_id }
  validates :item_type, presence: true, inclusion: { in: ITEM_TYPES }

  scope :vocab, -> { where(item_type: "vocab") }
  scope :grammar, -> { where(item_type: "grammar") }
  scope :kanji, -> { where(item_type: "kanji") }
  scope :sentences, -> { where(item_type: "sentence") }
end
