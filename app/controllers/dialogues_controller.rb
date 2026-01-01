class DialoguesController < ApplicationController
  before_action :set_user
  before_action :set_dialogue, only: [ :show, :start, :listen, :ready, :answer, :results ]

  def index
    @dialogues_count = @user.dialogues.count
    @attempts_count = @user.dialogue_attempts.completed.count
    @average_score = calculate_average_score
  end

  def show
    # Find the most recent in-progress attempt
    @attempt = @user.dialogue_attempts.in_progress.where(dialogue: @dialogue).order(created_at: :desc).first

    # If no in-progress attempt, create one and redirect
    unless @attempt
      @attempt = @user.dialogue_attempts.create!(
        dialogue: @dialogue,
        total_questions: DialogueAttempt::QUESTIONS_PER_ATTEMPT
      )
    end

    # If no answers yet, show dialogue. Otherwise show next question.
    # Filter out the "ready" placeholder when counting answers
    actual_answers = @attempt.answers.reject { |k, v| k == "ready" }

    if actual_answers.empty? && !@attempt.answers.key?("ready")
      @showing_dialogue = true
    else
      @current_question_index = actual_answers.keys.length + 1
      @current_question = @attempt.selected_questions[@current_question_index - 1]

      # If all questions answered, redirect to results
      if @current_question.nil?
        redirect_to results_dialogue_path(@dialogue) and return
      end
    end
  end

  def start
    # Always create a new attempt for fresh random questions
    @attempt = @user.dialogue_attempts.create!(
      dialogue: @dialogue,
      total_questions: DialogueAttempt::QUESTIONS_PER_ATTEMPT
    )

    redirect_to dialogue_path(@dialogue)
  end

  def listen
    @attempt = @user.dialogue_attempts.in_progress.where(dialogue: @dialogue).order(created_at: :desc).first

    unless @attempt
      @attempt = @user.dialogue_attempts.create!(
        dialogue: @dialogue,
        total_questions: DialogueAttempt::QUESTIONS_PER_ATTEMPT
      )
    end
  end

  def ready
    @attempt = @user.dialogue_attempts.in_progress.where(dialogue: @dialogue).order(created_at: :desc).first!

    # Select random questions if not already selected
    @attempt.select_random_questions! if @attempt.selected_question_ids.empty?

    # Mark that user has read the dialogue by adding a placeholder
    @attempt.update!(answers: { "ready" => true })

    redirect_to dialogue_path(@dialogue)
  end

  def answer
    @attempt = @user.dialogue_attempts.in_progress.where(dialogue: @dialogue).order(created_at: :desc).first!
    question = @dialogue.comprehension_questions.find(params[:question_id])

    selected_index = params[:selected_index].to_i
    is_correct = question.check_answer(selected_index)

    answers = @attempt.answers || {}
    answers[question.id.to_s] = {
      "selected_index" => selected_index,
      "correct" => is_correct
    }

    # Count correct answers, filtering out non-hash values like "ready"
    correct_count = answers.values.count { |a| a.is_a?(Hash) && a["correct"] }

    @attempt.update!(
      answers: answers,
      correct_count: correct_count
    )

    # Check if all questions answered (excluding "ready" placeholder)
    actual_answers = answers.reject { |k, v| k == "ready" }
    if actual_answers.keys.length >= @attempt.total_questions
      @attempt.mark_completed!
      redirect_to results_dialogue_path(@dialogue)
    else
      redirect_to dialogue_path(@dialogue)
    end
  end

  def results
    @attempt = @user.dialogue_attempts.completed.where(dialogue: @dialogue).order(created_at: :desc).first!
  end

  def new
    # Show generation form
  end

  def generate
    unless @user.openrouter_configured?
      redirect_to settings_path, alert: "Please configure your OpenRouter API key in settings before generating dialogues."
      return
    end

    unless @user.openai_configured?
      redirect_to settings_path, alert: "Please configure your OpenAI API key in settings for audio generation."
      return
    end

    count = params[:count].to_i.clamp(1, 20)
    difficulty = params[:difficulty_level] || "beginner"

    begin
      GenerateDialoguesJob.perform_now(@user.id, count: count, difficulty_level: difficulty)
      redirect_to root_path, notice: "Successfully generated #{count} #{difficulty} dialogue(s)!"
    rescue => e
      redirect_to new_dialogue_path, alert: "Error generating dialogues: #{e.message}"
    end
  end

  def destroy_all
    count = @user.dialogues.count
    @user.dialogues.destroy_all
    redirect_to root_path, notice: "Successfully deleted #{count} dialogue(s) and all associated data."
  end

  private

  def set_user
    @user = User.first
  end

  def set_dialogue
    @dialogue = Dialogue.find(params[:id])
  end

  def calculate_average_score
    completed = @user.dialogue_attempts.completed
    return 0 if completed.empty?

    (completed.average(:correct_count).to_f / completed.average(:total_questions).to_f * 100).round
  end
end
