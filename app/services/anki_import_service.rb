require "zip"
require "sqlite3"
require "tempfile"

class AnkiImportService
  class ImportError < StandardError; end

  def initialize(user, apkg_file_path)
    @user = user
    @apkg_file_path = apkg_file_path
    @imported_count = 0
    @updated_count = 0
    @skipped_count = 0
  end

  def import!
    validate_file!

    Dir.mktmpdir do |tmpdir|
      extract_apkg(tmpdir)
      db_path = find_anki_database(tmpdir)

      raise ImportError, "No Anki database found in .apkg file" unless db_path

      import_from_database(db_path)
    end

    {
      imported: @imported_count,
      updated: @updated_count,
      skipped: @skipped_count,
      total: @imported_count + @updated_count + @skipped_count
    }
  end

  private

  def validate_file!
    raise ImportError, "File not found: #{@apkg_file_path}" unless File.exist?(@apkg_file_path)
    raise ImportError, "File is not a .apkg file" unless @apkg_file_path.end_with?(".apkg")
  end

  def extract_apkg(tmpdir)
    Zip::File.open(@apkg_file_path) do |zip_file|
      zip_file.each do |entry|
        entry_path = File.join(tmpdir, entry.name)

        next if entry.directory?
        next if File.exist?(entry_path)

        FileUtils.mkdir_p(File.dirname(entry_path))

        File.open(entry_path, "wb") do |f|
          f.write(entry.get_input_stream.read)
        end
      end
    end
  rescue Zip::Error => e
    raise ImportError, "Failed to extract .apkg file: #{e.message}"
  end

  def find_anki_database(tmpdir)
    Dir.glob(File.join(tmpdir, "**", "*.anki2")).first ||
      Dir.glob(File.join(tmpdir, "**", "collection.anki2")).first
  end

  def import_from_database(db_path)
    db = SQLite3::Database.new(db_path)
    db.results_as_hash = true

    decks = parse_decks(db)

    cards_query = <<-SQL
      SELECT#{' '}
        cards.id as card_id,
        cards.nid as note_id,
        cards.did as deck_id,
        cards.type as card_type,
        cards.queue as card_queue,
        cards.ivl as interval,
        cards.factor as ease_factor,
        cards.reps as review_count,
        cards.lapses as lapse_count,
        notes.flds as fields,
        notes.tags as tags
      FROM cards
      JOIN notes ON cards.nid = notes.id
      WHERE cards.queue != -1
    SQL

    db.execute(cards_query).each do |row|
      process_card(row, decks)
    end

    db.close
  rescue SQLite3::Exception => e
    raise ImportError, "Failed to read Anki database: #{e.message}"
  end

  def parse_decks(db)
    col_row = db.execute("SELECT decks FROM col LIMIT 1").first
    return {} unless col_row

    decks_json = JSON.parse(col_row["decks"])
    decks_json.transform_values { |deck| deck["name"] }
  rescue JSON::ParserError
    {}
  end

  def process_card(row, decks)
    fields = row["fields"].split("\x1F")
    return if fields.empty?

    term = extract_term(fields[0])
    return if term.blank? || !contains_japanese?(term)

    reading = extract_reading(fields)
    meanings = extract_meanings(fields)
    tags = parse_tags(row["tags"])
    deck_name = decks[row["deck_id"].to_s] || "Unknown"

    vocab = @user.anki_vocabs.find_or_initialize_by(anki_card_id: row["card_id"])

    if vocab.new_record?
      vocab.assign_attributes(vocab_attributes(row, term, reading, meanings, tags, deck_name, fields))
      vocab.save!
      @imported_count += 1
    elsif vocab_needs_update?(vocab, row)
      vocab.update!(vocab_attributes(row, term, reading, meanings, tags, deck_name, fields))
      @updated_count += 1
    else
      @skipped_count += 1
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Failed to import card #{row['card_id']}: #{e.message}")
    @skipped_count += 1
  end

  def vocab_attributes(row, term, reading, meanings, tags, deck_name, fields)
    {
      anki_note_id: row["note_id"],
      term: term,
      reading: reading,
      meanings: meanings,
      tags: tags,
      card_type: row["card_type"],
      card_queue: row["card_queue"],
      interval_days: row["interval"],
      ease_factor: row["ease_factor"],
      review_count: row["review_count"],
      lapse_count: row["lapse_count"],
      deck_name: deck_name,
      note_fields: fields
    }
  end

  def vocab_needs_update?(vocab, row)
    vocab.review_count != row["review_count"] ||
      vocab.interval_days != row["interval"] ||
      vocab.card_type != row["card_type"] ||
      vocab.card_queue != row["card_queue"]
  end

  def extract_term(field)
    strip_html(field).strip
  end

  def extract_reading(fields)
    return nil if fields.length < 2
    reading = strip_html(fields[1]).strip
    reading.presence
  end

  def extract_meanings(fields)
    meanings = []

    fields.each_with_index do |field, index|
      next if index == 0

      cleaned = strip_html(field).strip
      next if cleaned.blank?
      next if contains_japanese?(cleaned)

      meanings << cleaned
    end

    meanings.uniq
  end

  def parse_tags(tags_string)
    return [] if tags_string.blank?
    tags_string.strip.split(/\s+/).reject(&:blank?)
  end

  def strip_html(text)
    text.gsub(/<[^>]*>/, "").gsub(/&nbsp;/, " ")
  end

  def contains_japanese?(text)
    text.match?(/[\p{Hiragana}\p{Katakana}\p{Han}]/)
  end
end
