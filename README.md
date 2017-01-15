# QuikChat::Client

Let the users quikchat!

## Installation

Add this line to your application's Gemfile:

    gem 'quikchat-client'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install quikchat-client

## Usage

List conversations for user
    `QuikChat.all_for_user_id(1, before_id: 100)`
List messages in conversation 123
    `QuikChat.new(id: 123).messages(before_id: 100)`
Post message to conversation 123
    `QuikChat.new(id: 123).post(sender: uid, body: msg)`
Post message to users
    `QuikChat.new(user_ids: [1,2,3]).post(sender: uid, body: msg)`

### Potential APIs in Ruby Web:

GET  /api/v1/quikchats
POST /api/v1/quikchats { recipients, message }
GET  /api/v1/quikchats/1239034
POST /api/v1/quikchats/1239034 { message }

### Service APIs in the service:

GET  /users/:user_id/conversations              conversations#index
POST /conversations                             conversations#create
GET  /conversations/:conversation_id/messages   messages#index
POST /conversations/:conversation_id/messages   messages#create

## Contributing

1. Fork it ( https://github.com/[my-github-username]/quikchat-client/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
