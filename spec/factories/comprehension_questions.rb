FactoryBot.define do
  factory :comprehension_question do
    dialogue
    question_text { "What does the speaker say?" }
    options { [ "Hello", "Goodbye", "Thank you", "Sorry" ] }
    correct_option_index { 0 }
    explanation { "The speaker greets with 'こんにちは' which means 'Hello'." }
  end
end
