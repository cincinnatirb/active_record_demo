class FixUserTweetReference < ActiveRecord::Migration[6.0]
  def change
    change_column :tweets, :user_id, :integer, null: false, foreign_key: true
  end
end
