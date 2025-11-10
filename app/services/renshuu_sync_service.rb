class RenshuuSyncService
  attr_reader :user, :client

  def initialize(user)
    @user = user
    @client = RenshuuClient.new(user.renshuu_api_key)
  end

  def sync_all
    sync_all_terms
    user.update!(last_renshuu_sync: Time.current)
  end

  def sync_all_terms
    Rails.logger.info("Syncing all terms for user #{user.id}")

    total_synced = 0

    # Sync each term type: vocab, kanji, grammar, sentence
    %w[vocab kanji grammar sentence].each do |term_type|
      synced_count = sync_terms_by_type(term_type)
      total_synced += synced_count
      Rails.logger.info("Synced #{synced_count} #{term_type} terms")
    end

    Rails.logger.info("Total terms synced: #{total_synced}")
  end

  def sync_terms_by_type(term_type)
    page = 1
    total_synced = 0

    loop do
      response = client.get_all_terms(term_type, page: page)
      contents = response["contents"] || {}
      terms = contents["terms"] || []

      break if terms.empty?

      terms.each do |term_data|
        sync_term(term_data, term_type)
        total_synced += 1
      end

      # Check if there are more pages
      total_pages = contents["total_pg"] || 1
      break if page >= total_pages

      page += 1
    end

    total_synced
  end

  private

  def sync_term(term_data, term_type)
    user.renshuu_items.find_or_initialize_by(
      external_id: term_data["id"]
    ).tap do |item|
      item.item_type = term_type

      case term_type
      when "vocab"
        item.term = term_data["kanji_full"] || term_data["hiragana_full"]
        item.reading = term_data["hiragana_full"]
        item.meanings = term_data["def"] || []
        item.tags = (term_data["markers"] || []) + (term_data["config"] || [])
        item.example_sentences = []
      when "kanji"
        item.term = term_data["kanji"]
        item.reading = term_data["kunyomi"] || term_data["onyomi"]
        item.meanings = [ term_data["definition"] ].compact
        item.tags = [ term_data["jlpt"], term_data["kanken"] ].compact
        item.example_sentences = []
      when "grammar"
        item.term = term_data["title_japanese"]
        item.reading = term_data["title_japanese"]
        item.meanings = [ term_data.dig("meaning", "eng"), term_data.dig("meaning_long", "eng") ].compact
        item.grammar_point = term_data["title_english"]
        item.example_sentences = term_data["models"] || []
        item.tags = []
      when "sentence"
        item.term = term_data["japanese"]
        item.reading = term_data["hiragana"]
        item.meanings = [ term_data.dig("meaning", "en") ].compact
        item.example_sentences = []
        item.tags = []
      end

      # Extract mastery level from user_data if available
      if term_data["user_data"]
        item.mastery_level = term_data["user_data"]["mastery_avg_perc"] || 0
      end

      item.save!
    end
  end
end
