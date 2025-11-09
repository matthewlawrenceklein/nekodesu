namespace :dialogues do
  desc "Generate dialogues for a user"
  task :generate, [ :user_id, :count, :difficulty ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id
    count = (args[:count] || 10).to_i
    difficulty = args[:difficulty] || "beginner"

    unless user_id
      puts "No user found. Please create a user first."
      exit 1
    end

    user = User.find(user_id)

    unless user.openrouter_configured?
      puts "User #{user_id} does not have OpenRouter API key configured."
      puts "Please set the OPENROUTER_API_KEY environment variable or add it to the user."
      exit 1
    end

    puts "Queueing generation of #{count} #{difficulty} dialogues for user #{user_id}..."
    GenerateDialoguesJob.perform_later(user_id, count: count, difficulty_level: difficulty)
    puts "Job queued! Check the GoodJob dashboard at http://localhost:3000/good_job"
  end

  desc "Generate dialogues synchronously (for testing)"
  task :generate_now, [ :user_id, :count, :difficulty ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id
    count = (args[:count] || 10).to_i
    difficulty = args[:difficulty] || "beginner"

    unless user_id
      puts "No user found. Please create a user first."
      exit 1
    end

    user = User.find(user_id)

    unless user.openrouter_configured?
      puts "User #{user_id} does not have OpenRouter API key configured."
      puts "Please set the OPENROUTER_API_KEY environment variable or add it to the user."
      exit 1
    end

    puts "Generating #{count} #{difficulty} dialogues for user #{user_id}..."
    GenerateDialoguesJob.perform_now(user_id, count: count, difficulty_level: difficulty)
    puts "Done! Generated dialogues:"

    user.dialogues.recent.limit(count).each do |dialogue|
      puts "  - #{dialogue.id}: #{dialogue.japanese_text.truncate(50)}"
    end
  end

  desc "List dialogues for a user"
  task :list, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id

    unless user_id
      puts "No user found."
      exit 1
    end

    user = User.find(user_id)
    dialogues = user.dialogues.recent

    puts "Dialogues for user #{user_id} (#{dialogues.count} total):"
    puts ""

    dialogues.each do |dialogue|
      puts "ID: #{dialogue.id}"
      puts "Difficulty: #{dialogue.difficulty_level} (Levels #{dialogue.level_range})"
      puts "Japanese: #{dialogue.japanese_text.truncate(80)}"
      puts "English: #{dialogue.english_translation.truncate(80)}"
      puts "Questions: #{dialogue.comprehension_questions.count}"
      puts "Created: #{dialogue.created_at.strftime('%Y-%m-%d %H:%M')}"
      puts "-" * 80
    end
  end
end
