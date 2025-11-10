namespace :renshuu do
  desc "Sync Renshuu data for a specific user"
  task :sync, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id

    unless user_id
      puts "No user found"
      exit 1
    end

    user = User.find(user_id)

    unless user.renshuu_configured?
      puts "User #{user_id} does not have a Renshuu API key configured"
      exit 1
    end

    puts "Syncing Renshuu data for user #{user_id}..."
    service = RenshuuSyncService.new(user)
    service.sync_all

    puts "\nSync complete!"
    puts "Total items: #{user.renshuu_items.count}"
    puts "  - Vocab: #{user.renshuu_items.vocab.count}"
    puts "  - Grammar: #{user.renshuu_items.grammar.count}"
    puts "  - Kanji: #{user.renshuu_items.kanji.count}"
    puts "  - Sentences: #{user.renshuu_items.sentences.count}"
  end

  desc "Sync Renshuu data for all users"
  task sync_all: :environment do
    puts "Syncing Renshuu data for all configured users..."

    User.find_each do |user|
      next unless user.renshuu_configured?

      puts "\nSyncing user #{user.id} (#{user.email})..."
      begin
        service = RenshuuSyncService.new(user)
        service.sync_all
        puts "✓ Success"
      rescue StandardError => e
        puts "✗ Failed: #{e.message}"
      end
    end

    puts "\nAll syncs complete!"
  end

  desc "Clear all Renshuu data and resync for a user"
  task :reset_and_resync, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id

    unless user_id
      puts "No user found"
      exit 1
    end

    user = User.find(user_id)

    puts "Clearing all Renshuu items for user #{user_id}..."
    deleted_items = user.renshuu_items.delete_all
    puts "Deleted #{deleted_items} items"

    puts "Resetting last sync time..."
    user.update!(last_renshuu_sync: nil)

    puts "\nStarting fresh sync..."
    service = RenshuuSyncService.new(user)
    service.sync_all

    puts "\nSync complete!"
    puts "Total items: #{user.renshuu_items.count}"
    puts "  - Vocab: #{user.renshuu_items.vocab.count}"
    puts "  - Grammar: #{user.renshuu_items.grammar.count}"
    puts "  - Kanji: #{user.renshuu_items.kanji.count}"
    puts "  - Sentences: #{user.renshuu_items.sentences.count}"
  end
end
