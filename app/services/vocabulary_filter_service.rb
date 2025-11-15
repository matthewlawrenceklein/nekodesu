class VocabularyFilterService
  def initialize(user)
    @user = user
    @known_kanji = load_known_kanji
  end

  # Filters Renshuu vocabulary into two tiers:
  # - safe: vocabulary where all kanji are known (can use as-is)
  # - hiragana_only: vocabulary with unknown kanji (use hiragana reading)
  # Returns: { safe: [...], hiragana_only: [...] }
  def filter_renshuu_vocabulary
    renshuu_vocab = @user.renshuu_items.vocab

    safe = []
    hiragana_only = []

    renshuu_vocab.each do |item|
      kanji_in_word = extract_kanji(item.term)

      if kanji_in_word.empty?
        # No kanji in the word, safe to use as-is
        safe << item.term
      elsif all_kanji_known?(kanji_in_word)
        # All kanji are known, safe to use with kanji
        safe << item.term
      elsif item.reading.present?
        # Has unknown kanji but we have hiragana reading
        hiragana_only << item.reading
      end
      # If no reading available and has unknown kanji, skip this vocab
    end

    { safe: safe, hiragana_only: hiragana_only }
  end

  private

  def load_known_kanji
    wani_kanji = @user.wani_subjects.visible.kanji.pluck(:characters)
    renshuu_kanji = @user.renshuu_items.kanji.pluck(:term)
    (wani_kanji + renshuu_kanji).uniq
  end

  def extract_kanji(text)
    text.scan(/[\u4E00-\u9FAF]/)
  end

  def all_kanji_known?(kanji_array)
    kanji_array.all? { |k| @known_kanji.include?(k) }
  end
end
