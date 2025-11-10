namespace :wanikani do
  desc "Clear all subjects and resync based on user level"
  task :reset_and_resync, [ :user_id ] => :environment do |t, args|
    user_id = args[:user_id] || User.first&.id

    unless user_id
      puts "No user found"
      exit 1
    end

    user = User.find(user_id)

    puts "Clearing all subjects for user #{user_id}..."
    deleted_count = user.wani_subjects.delete_all
    puts "Deleted #{deleted_count} subjects"

    puts "Resetting last sync time..."
    user.update!(last_wanikani_sync: nil)

    puts "\nStarting fresh sync..."
    service = WanikaniSyncService.new(user)
    service.sync_all

    puts "\nSync complete!"
    puts "User level: #{user.level}"
    puts "Total subjects: #{user.wani_subjects.count}"
    puts "  - Radicals: #{user.wani_subjects.where(subject_type: 'radical').count}"
    puts "  - Kanji: #{user.wani_subjects.where(subject_type: 'kanji').count}"
    puts "  - Vocabulary: #{user.wani_subjects.where(subject_type: 'vocabulary').count}"
  end
end
