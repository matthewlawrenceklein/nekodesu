class WanikaniSyncService
  attr_reader :user, :client

  def initialize(user)
    @user = user
    @client = WanikaniClient.new(user.wanikani_api_key)
  end

  def sync_all
    sync_subjects
    sync_study_materials
    user.update!(last_wanikani_sync: Time.current)
  end

  def sync_study_materials
    Rails.logger.info("Syncing study materials for user #{user.id}")

    params = {}
    params[:updated_after] = user.last_wanikani_sync.iso8601 if user.last_wanikani_sync

    all_materials = fetch_all_pages(:get_study_materials, params)

    all_materials.each do |material_data|
      sync_study_material(material_data)
    end

    Rails.logger.info("Synced #{all_materials.count} study materials")
  end

  def sync_subjects
    Rails.logger.info("Syncing subjects for user #{user.id}")

    params = {}
    params[:updated_after] = user.last_wanikani_sync.iso8601 if user.last_wanikani_sync

    all_subjects = fetch_all_pages(:get_subjects, params)

    all_subjects.each do |subject_data|
      sync_subject(subject_data)
    end

    Rails.logger.info("Synced #{all_subjects.count} subjects")
  end

  private

  def fetch_all_pages(method, params = {})
    results = []
    next_url = nil

    loop do
      response = if next_url
        fetch_from_url(next_url)
      else
        client.send(method, params)
      end

      results.concat(response["data"]) if response["data"]

      next_url = response.dig("pages", "next_url")
      break unless next_url
    end

    results
  end

  def fetch_from_url(url)
    uri = URI.parse(url)
    path_with_query = "#{uri.path}?#{uri.query}"
    ssl_verify = Rails.env.production?

    connection = Faraday.new(url: "#{uri.scheme}://#{uri.host}", ssl: { verify: ssl_verify }) do |conn|
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.adapter Faraday.default_adapter
    end

    response = connection.get(path_with_query) do |req|
      req.headers["Authorization"] = "Bearer #{user.wanikani_api_key}"
      req.headers["Wanikani-Revision"] = WanikaniClient::API_REVISION
    end

    response.body
  end

  def sync_study_material(material_data)
    data = material_data["data"]

    wani_subject = user.wani_subjects.find_by(external_id: data["subject_id"])
    return unless wani_subject

    user.wani_study_materials.find_or_initialize_by(
      external_id: material_data["id"]
    ).tap do |material|
      material.wani_subject = wani_subject
      material.subject_id = data["subject_id"]
      material.subject_type = data["subject_type"]
      material.meaning_note = data["meaning_note"]
      material.reading_note = data["reading_note"]
      material.meaning_synonyms = data["meaning_synonyms"] || []
      material.hidden = data["hidden"] || false
      material.created_at_wanikani = data["created_at"]
      material.save!
    end
  end

  def sync_subject(subject_data)
    data = subject_data["data"]

    user.wani_subjects.find_or_initialize_by(
      external_id: subject_data["id"]
    ).tap do |subject|
      subject.subject_type = subject_data["object"]
      subject.characters = data["characters"]
      subject.slug = data["slug"]
      subject.level = data["level"]
      subject.lesson_position = data["lesson_position"]
      subject.meaning_mnemonic = data["meaning_mnemonic"]
      subject.reading_mnemonic = data["reading_mnemonic"]
      subject.document_url = data["document_url"]
      subject.meanings = data["meanings"] || []
      subject.auxiliary_meanings = data["auxiliary_meanings"] || []
      subject.readings = data["readings"] || []
      subject.component_subject_ids = data["component_subject_ids"] || []
      subject.hidden_at = data["hidden_at"]
      subject.created_at_wanikani = data["created_at"]
      subject.save!
    end
  end
end
