class AnkiVocab < ApplicationRecord
  belongs_to :user

  validates :anki_card_id, presence: true, uniqueness: { scope: :user_id }

  scope :new_cards, -> { where(card_type: 0) }
  scope :learning, -> { where(card_type: 1) }
  scope :review, -> { where(card_type: 2) }
  scope :relearning, -> { where(card_type: 3) }

  scope :active, -> { where.not(card_queue: -1) }
  scope :suspended, -> { where(card_queue: -1) }

  scope :well_known, -> { where("interval_days >= ?", 21).where(card_type: 2) }
  scope :struggling, -> { where("lapse_count >= ?", 3) }

  def mastery_level
    return :new if card_type == 0
    return :learning if card_type == 1
    return :relearning if card_type == 3
    return :struggling if lapse_count >= 3

    if card_type == 2
      return :master if interval_days >= 120
      return :proficient if interval_days >= 60
      return :familiar if interval_days >= 21
      return :learning
    end

    :unknown
  end

  def known?
    card_type == 2 && interval_days >= 21
  end
end
