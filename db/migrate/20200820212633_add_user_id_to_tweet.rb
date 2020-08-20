class AddUserIdToTweet < ActiveRecord::Migration[6.0]
  def change
    add_reference :tweets, :user, null: true
  end
end
