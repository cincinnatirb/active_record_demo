namespace :data do
  desc "Extracts Users from Tweets"
  task extract_user_from_tweet: :environment do
    tweets = Tweet.where(user_id: nil)

    puts "Extracting Users from #{tweets.count} Tweets..."

    tweets.each do |tweet|
      user = User.find_or_create_by(username: tweet.username)
      tweet.update(user: user)
    end

    puts "Done. Created #{User.count} Users."
  end
end
