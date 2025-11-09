class DialoguesController < ApplicationController
  before_action :set_user
  before_action :set_dialogue, only: [ :show, :start, :ready, :answer, :results ]

  def index
    @dialogues_count = @user.dialogues.count
    @attempts_count = @user.dialogue_attempts.completed.count
    @average_score = calculate_average_score
  end

  def show
    @attempt = @user.dialogue_attempts.find_or_create_by(dialogue: @dialogue) do |attempt|
      attempt.total_questions = @dialogue.comprehension_questions.count
    end

    # If no answers yet, show dialogue. Otherwise show next question.
    # Filter out the "ready" placeholder when counting answers
    actual_answers = @attempt.answers.reject { |k, v| k == "ready" }

    if actual_answers.empty? && !@attempt.answers.key?("ready")
      @showing_dialogue = true
    else
      @current_question_index = actual_answers.keys.length + 1
      @current_question = @dialogue.comprehension_questions.order(:id)[@current_question_index - 1]

      # If all questions answered, redirect to results
      if @current_question.nil?
        redirect_to results_dialogue_path(@dialogue) and return
      end
    end
  end

  def start
    @attempt = @user.dialogue_attempts.find_or_create_by(dialogue: @dialogue) do |attempt|
      attempt.total_questions = @dialogue.comprehension_questions.count
    end

    redirect_to dialogue_path(@dialogue)
  end

  def ready
    @attempt = @user.dialogue_attempts.find_or_create_by!(dialogue: @dialogue) do |attempt|
      attempt.total_questions = @dialogue.comprehension_questions.count
    end

    # Mark that user has read the dialogue by adding a placeholder
    @attempt.update!(answers: { "ready" => true })

    redirect_to dialogue_path(@dialogue)
  end

  def answer
    @attempt = @user.dialogue_attempts.find_by!(dialogue: @dialogue)
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
    if actual_answers.keys.length >= @dialogue.comprehension_questions.count
      @attempt.mark_completed!
      redirect_to results_dialogue_path(@dialogue)
    else
      redirect_to dialogue_path(@dialogue)
    end
  end

  def results
    @attempt = @user.dialogue_attempts.find_by!(dialogue: @dialogue, completed_at: ...Time.current)
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
