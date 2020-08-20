# ActiveRecord Demo
In this demo we will:
* Revisit Rails generators
* Learn more about Microsoft's Visual Studio Code and some of its features
* Expand our use of git for source code control
* Explore use of the DB Browser for SQLite to explore the internals of a SQL database
* Be quickly introduced to Rails routing, controllers and views
* Implement our first feature request
* Learn about ActiveRecord, including Associations and Migrations
* Learn how define Rake tasks
* Use the Rails console

## 1. Prerequisites
* Ubuntu 20 LTS: https://www.youtube.com/watch?v=I8WhikkiiSI
* Ruby, Node and Yarn: https://www.youtube.com/watch?v=C_xhTo9bw0s
* Microsoft Visual Studio Code: https://www.youtube.com/watch?v=rizfyb1-u6Q

## 2. Starting from `rails new`
Let's create our Rails application and take a quick tour of the Visual Source Code IDE.
```sh
rails new active_record_demo
code active_record_demo
```
1. Open the integrated terminal.
1. Change to Source Control view.

## 3. A word about git...
Experience with [Git](https://git-scm.com/) is not a requirement for this
demo but seeing it in use should develop a familiarity with it that will aid
in comprehension when you decide to learn more.
```sh
git add .
git commit -m'rails new active_record_demo'
git config -l
git config --global user.email "bill@gaslight.co"
git config --global user.name "Bill Barnett"
git config -l
git commit -m'rails new active_record_demo'
git log
```

## 4. Where were we?!
This is where we left off from the [MVC & Routes demo](https://www.youtube.com/watch?v=XRwGB0TpB1g).
```sh
rails generate scaffold Tweet username:string message:string
git add .
git commit -m'rails generate scaffold Tweet username:string message:string'
git log
rails server
```
What happens when you visited http://localhost:3000/ ?

## 5. BANG! Our first encounter with ActiveRecord.
Let's fix the PendingMigrationError issue and explore the innards of a SQL
database. Open the [DB Browser for SQLite](https://sqlitebrowser.org/)
application. Then open the `db/development.sqlite3` database file and explore
the contents of the database.
```sh
rails db:migrate
sudo snap install --candidate sqlitebrowser
git add db/schema.rb
git commit -m'rails db:migrate'
git log
```

## 6. A word about routing...
We'll add this line at the top of the `config/routes.rb` file. Now when we
visit the application `root` URL we'll see the index view of Tweets instead of
the default "Yay, you're on Rails" view.
```ruby
# config/routes.rb
Rails.application.routes.draw do
  root 'tweets#index'
  [...]
end
```
And commit that.
```sh
git add config/routes.rb
git commit -m'Make tweets#index the root'
git log
```

## 7. Let's add some data!
Start the Rails server if it isn't already running. You'll receive the "A
server is already running" error message if it already is.
```sh
rails server
```
1. Add a few Tweets with at least two with the same username.
1. Examine the new data in the DB Browser.
1. Compare the database contents with the data displayed in the browser.
1. Edit and then delete a record and look at the database after each action.

## 8. How is Rails doing that?! Easy, ActiveRecord.
The secret lies in the `TweetsController`.
1. Open `app/controllers/tweets_controller.rb`.
1. The `index` method fetches all the Tweets from the database with `Tweet.all`.
1. The `new` method builds a new "bank" Tweet with `Tweet.new` which needs no call to the database.
1. The `create` method received the `new` form data and calls `@tweet.save`, saving the new Tweet in the database.
1. The `update` method calls `@tweet.update` with the changes received from the `edit` form, saving the updated Tweet in the database.
1. The `destroy` method calls `@tweet.destroy` removing the Tweet from the database.
1. But what's up with the `edit` and `show` methods?!
```sh
rails routes -c TweetsController
```
Each route maps to a method in the TweetsController. What's the significance of
the `before_action`? What do the methods defined beneath `private` do?

## 9. Feature request!
We've been asked to create a view that displays all the Tweets for a specific
**User** AND include that **User's** bio. Now what? We could add a `bio`
attribute to the Tweet model but the bio seems to be an attribute of the
**User** rather than the tweet.

Let's generate a new model called `User` via Rails' scaffold generator so we
get all the MVC goodness for free. Also, notice we can amend an existing commit
if we decide more work was needed before we have pushed the commits to a remote
repository.
```sh
rails generate scaffold User username:string bio:string
rails db:migrate
git add .
git commit -m'rails generate scaffold User username:string bio:string && rails db:migrate'
# Open config/routes.rb and place "resources :users" alphabetically.
git add config/routes.rb
git commit --amend -m'rails generate scaffold User username:string bio:string && rails db:migrate'
```

## 10. Refactoring, Migrations and Associations... Oh my!
In our simple case, we'll define `belongs_to` and `has_many` macros but there
are [many association types](https://guides.rubyonrails.org/association_basics.html#the-types-of-associations)
in Rails and care should be taken that they're two-way. In our case this means
that if a `Tweet` references a `User` then the reciprocal `has_many`
association should exist in the `User` class definition.
```ruby
# app/models/tweet.rb
class Tweet < ApplicationRecord
  belongs_to :user, optional: true
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :tweets
end
```

Now that our classes are wired up we need a mechanism for supporting this
relationship in the database. Rails migrations to the rescue.

Why did we not have to edit the migration? How does Rails know to "do the
right thing?"
```sh
rails generate migration add_user_id_to_tweet user:references
# Change null constraint to true and remove foreign key constraint from the
# migration for now.
rails db:migrate
```

## 11. Rake
Shout out to [Jim Weirich](https://en.wikipedia.org/wiki/Jim_Weirich), the
creator of Rake, Cincinnati Ruby Brigade member and inspiration human being.
Once again, Rails generators to the rescue.
```sh
rails generate task data extract_user_from_tweet
```

Now we'll write some Ruby to iterate over all the existing `Tweets` and create
a new `User` when we encounter a `Tweet` for a `User that does not exist AND
assign the `User` (new or existing) to the associated `Tweet`.
```ruby
# lib/tasks/data.rake
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
```

Finally, let's run the rake task. Look familiar? (e.g., `rails db:migrate`)
```sh
rails data:extract_user_from_tweet
```
1. Look at that data. How many Tweets are there? How many Users were created?
1. Update the name of a Tweet. Did the username change on the User?
1. Hmmm... What should be the "single source of truth" for the username
associated with a `Tweet`?

It's a good time to commit our changes.
```sh
git add .
git commit -m'Extract User from Tweet'
git log
```

## 12. Restoring the Relationship
For simplicity, we broke some of Rails built-in features that ensure the
referential integrity of our data. It's safe now, and appropriate to fix the
code implementing this relationship.

Say it with me, "...and we'll use a generator to do it!"
```sh
rails generate migration fix_user_tweet_reference
```

We'll change the `user_id` column in the `tweets` table to ensure it contains a
`User#id` and is defined as a foreign key for the `users` table.
```ruby
class FixUserTweetReference < ActiveRecord::Migration[6.0]
  def change
    change_column :tweets, :user_id, :integer, null: false, foreign_key: true
  end
end
```

We also need to remove the `optional: true` property of the association since
we now desire that a `User` is required for the `Tweet` to be valid.
```ruby
# app/models/tweet.rb
class Tweet < ApplicationRecord
  belongs_to :user
end
```

To finalize everything we have to run the migration which is the perfect time
to commit our changes.
```sh
rails db:migrate
git add .
git commit -m'Fix Tweet-User reference'
```

## 13. The Rails Console
Let's fire up the Rails console which is a REPL (read, evaluate, print loop)
utility baked into Rails that loads the application code making direct
manipulation of ActiveRecord objects possible.
```sh
rails console
```

Run these code examples in the console and make note not only of what is
returned by each line but what other information is output. See any SQL?
```irb
irb(main):001:0> first_user = User.first
irb(main):002:0> first_user
irb(main):003:0> first_user.tweets
irb(main):004:0> first_tweet = first_user.tweets.first
irb(main):005:0> first_tweet
irb(main):006:0> first_tweet.user
irb(main):007:0> new_tweet = Tweet.new
irb(main):008:0> new_tweet.valid?
irb(main):009:0> new_tweet.errors.messages
```

## 14. Clean-up
Let's remove the data duplication that exists due to the presence of a
`username` attribute in both the `tweets` and `users` tables.

Yep, another migration.
```sh
rails generate migration remove_username_from_tweet
```

```ruby
class RemoveUsernameFromTweet < ActiveRecord::Migration[6.0]
  def change
    remove_column :tweets, :username, :string
  end
end
```

Run the migration and start the server if it isn't already running. Remember
what will happen if it already is running?
```sh
rails db:migrate
rails server
```

1. Visit http://localhost:3000/
1. Oops!

We need to fix the reference to `tweet.username` in the view that renders the
table of tweets. We'll replace it with `tweet.user.username` and make it a
link to the associated user's show page.
```ruby
# app/views/tweets/index.html.erb
<p id="notice"><%= notice %></p>

<h1>Tweets</h1>

<table>
  <thead>
    <tr>
      <th>Username</th>
      <th>Message</th>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @tweets.each do |tweet| %>
      <tr>
        <td><%= link_to tweet.user.username, user_path(tweet.user) %></td>
        <td><%= tweet.message %></td>
        <td><%= link_to 'Show', tweet %></td>
        <td><%= link_to 'Edit', edit_tweet_path(tweet) %></td>
        <td><%= link_to 'Destroy', tweet, method: :delete, data: { confirm: 'Are you sure?' } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to 'New Tweet', new_tweet_path %>
```

Finally, while we're fixing views, we'll add a simple table to display all of a
user's tweets on their show page which will complete our feature request!
```ruby
# app/views/users/show.html.erb
<p id="notice"><%= notice %></p>

<p>
  <strong>Username:</strong>
  <%= @user.username %>
</p>

<p>
  <strong>Bio:</strong>
  <%= @user.bio %>
</p>


<h2>Tweets</h2>
<table>
  <thead>
    <tr>
      <th>Message</th>
      <th>Posted</th>
    </tr>
  </thead>

  <tbody>
    <% @user.tweets.each do |tweet| %>
      <tr>
        <td><%= tweet.message %></td>
        <td><%= tweet.created_at %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<%= link_to 'Edit', edit_user_path(@user) %> |
<%= link_to 'Back', users_path %>
```

Of course, we're not really done until we've pushed our changes.
```sh
git add .
git commit -m'Remove username from Tweet and fix up views'
git log
```

## Exercises
The new `Tweet` form is broken? (See: http://localhost:3000/tweets/new)
1. Why is it broken?
1. How would you fix it?

## Further Reading
* The Active Record Pattern: https://en.wikipedia.org/wiki/Active_record_pattern
* The ActiveRecord Gem: https://rubygems.org/gems/activerecord
* The ActiveRecord Rails Guide: https://guides.rubyonrails.org/active_record_basics.html

Expanded from: https://gist.github.com/agilous/7a9b8b4bc40dabd4490146bd19bd19ad
