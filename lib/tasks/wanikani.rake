namespace :wanikani do
  desc "Sync WaniKani data for a user"
  task :sync, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id

    unless user_id
      puts "No user found. Please create a user first."
      exit 1
    end

    user = User.find(user_id)

    unless user.wanikani_configured?
      puts "User #{user_id} does not have WaniKani API key configured."
      exit 1
    end

    puts "Starting WaniKani sync for user #{user.email}..."

    service = WanikaniSyncService.new(user)
    service.sync_all

    puts "Sync complete!"
    puts "Subjects: #{user.wani_subjects.count}"
    puts "Study Materials: #{user.wani_study_materials.count}"
  end

  desc "Test WaniKani API connection"
  task :test_connection, [ :api_key ] => :environment do |t, args|
    api_key = args[:api_key] || ENV["WANIKANI_API_KEY"]

    unless api_key
      puts "Please provide an API key: rake wanikani:test_connection[YOUR_API_KEY]"
      exit 1
    end

    puts "Testing WaniKani API connection..."

    client = WanikaniClient.new(api_key)
    user_data = client.get_user

    puts "✓ Connection successful!"
    puts "Username: #{user_data.dig('data', 'username')}"
    puts "Level: #{user_data.dig('data', 'level')}"
    puts "Subscription: #{user_data.dig('data', 'subscription', 'type')}"
  rescue WanikaniClient::AuthenticationError
    puts "✗ Authentication failed. Please check your API key."
    exit 1
  rescue => e
    puts "✗ Error: #{e.message}"
    exit 1
  end
end
