class KanjiReplacementService
  def initialize(user)
    @user = user
    @known_kanji = load_known_kanji
    @vocabulary_map = build_vocabulary_map
  end

  # Main method: processes text based on user's display mode preference
  def process_text(text)
    unknown_kanji = find_unknown_kanji(text)
    return text if unknown_kanji.empty?

    case @user.unknown_kanji_display_mode
    when "hiragana"
      replace_with_hiragana(text, unknown_kanji)
    when "furigana"
      add_furigana(text, unknown_kanji)
    else
      text
    end
  end

  private

  def load_known_kanji
    wani_kanji = @user.wani_subjects.visible.kanji.pluck(:characters)
    renshuu_kanji = @user.renshuu_items.kanji.pluck(:term)
    (wani_kanji + renshuu_kanji).uniq
  end

  def build_vocabulary_map
    # Build a map of vocabulary words to their readings
    # This includes both WaniKani and Renshuu vocabulary
    map = {}

    # Renshuu vocabulary (has readings)
    @user.renshuu_items.vocab.each do |item|
      map[item.term] = item.reading if item.reading.present?
    end

    map
  end

  def find_unknown_kanji(text)
    # Use the same logic as unknown_kanji_in_text helper
    # Only consider kanji as "known" if explicitly studied as individual kanji
    # NOT if they just appear in vocabulary words
    kanji_in_text = text.scan(/[\u4E00-\u9FAF]/).uniq
    
    # Get explicitly studied kanji only (not from vocabulary)
    wani_kanji = @user.wani_subjects.visible.kanji.pluck(:characters)
    renshuu_kanji = @user.renshuu_items.kanji.pluck(:term)
    explicitly_known = (wani_kanji + renshuu_kanji).uniq
    
    kanji_in_text - explicitly_known
  end

  # Replace unknown kanji with hiragana readings
  def replace_with_hiragana(text, unknown_kanji)
    result = text.dup

    # Sort vocabulary by length (longest first) to avoid partial replacements
    sorted_vocab = @vocabulary_map.keys.sort_by { |k| -k.length }

    sorted_vocab.each do |word|
      next unless result.include?(word)

      # Check if this word contains unknown kanji
      word_kanji = word.scan(/[\u4E00-\u9FAF]/)
      if (word_kanji & unknown_kanji).any?
        # Replace the word with its hiragana reading
        result.gsub!(word, @vocabulary_map[word])
      end
    end

    result
  end

  # Add furigana (ruby tags) for words with unknown kanji
  def add_furigana(text, unknown_kanji)
    result = text.dup

    # Sort vocabulary by length (longest first) to avoid partial replacements
    sorted_vocab = @vocabulary_map.keys.sort_by { |k| -k.length }

    # Track positions we've already processed to avoid double-processing
    processed_ranges = []

    sorted_vocab.each do |word|
      next unless result.include?(word)

      # Check if this word contains unknown kanji
      word_kanji = word.scan(/[\u4E00-\u9FAF]/)
      next unless (word_kanji & unknown_kanji).any?

      # Find all occurrences of this word
      offset = 0
      while (index = result.index(word, offset))
        range = index...(index + word.length)

        # Skip if this range overlaps with already processed text
        unless processed_ranges.any? { |r| ranges_overlap?(r, range) }
          # Replace with ruby tag
          reading = @vocabulary_map[word]
          ruby_tag = "<ruby>#{word}<rt>#{reading}</rt></ruby>"

          result[range] = ruby_tag
          processed_ranges << (index...(index + ruby_tag.length))

          # Adjust offset for next search
          offset = index + ruby_tag.length
        else
          offset = index + word.length
        end
      end
    end

    result
  end

  def ranges_overlap?(range1, range2)
    range1.cover?(range2.begin) || range2.cover?(range1.begin)
  end
end
