json.extract! tweet, :id, :username, :message, :created_at, :updated_at
json.url tweet_url(tweet, format: :json)
