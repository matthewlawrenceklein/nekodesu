class SettingsController < ApplicationController
  before_action :set_user

  def show
    @anki_vocab_count = @user.anki_vocabs.count
    @well_known_count = @user.anki_vocabs.well_known.count
  end

  def update
    if @user.update(user_params)
      redirect_to settings_path, notice: "Settings updated successfully!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def import_anki
    unless params[:apkg_file].present?
      redirect_to settings_path, alert: "Please select an .apkg file to import."
      return
    end

    uploaded_file = params[:apkg_file]

    unless uploaded_file.original_filename.end_with?(".apkg")
      redirect_to settings_path, alert: "Please upload a valid .apkg file."
      return
    end

    tempfile_path = save_uploaded_file(uploaded_file)

    begin
      service = AnkiImportService.new(@user, tempfile_path)
      result = service.import!

      message = "Successfully imported Anki deck! " \
                "#{result[:imported]} new cards, " \
                "#{result[:updated]} updated, " \
                "#{result[:skipped]} skipped."

      redirect_to settings_path, notice: message
    rescue AnkiImportService::ImportError => e
      redirect_to settings_path, alert: "Import failed: #{e.message}"
    ensure
      File.delete(tempfile_path) if tempfile_path && File.exist?(tempfile_path)
    end
  end

  def destroy_anki
    count = @user.anki_vocabs.count
    @user.anki_vocabs.destroy_all
    redirect_to settings_path, notice: "Successfully deleted #{count} Anki vocabulary items."
  end

  private

  def set_user
    @user = User.first
  end

  def user_params
    params.require(:user).permit(
      :wanikani_api_key,
      :renshuu_api_key,
      :openrouter_api_key,
      :openai_api_key,
      :speech_speed
    )
  end

  def save_uploaded_file(uploaded_file)
    tempfile = Tempfile.new([ "anki_import", ".apkg" ])
    tempfile.binmode
    tempfile.write(uploaded_file.read)
    tempfile.close
    tempfile.path
  end
end
