require 'watir'
require 'pry'
require 'firebase'
require_relative './twitter_messenger'



handles = File.readlines('twitter_handles.txt').map(&:strip)

messenger = TwitterMessenger.new
messenger.create_browser_and_login
handles.each do |handle|
  messenger.send_intro_message(handle)
end


# base_uri = 'https://twitter-outreach.firebaseio.com/'

# firebase = Firebase::Client.new(base_uri)

# response = firebase.push("user", { handle: '@fish', directMessageEnabled: false })
# response.success? # => true
# response.code # => 200
# response.body # => { 'name' => "-INOQPH-aV_psbk3ZXEX" }
# response.raw_body # => '{"name":"-INOQPH-aV_psbk3ZXEX"}'
# binding.pry

# b = Watir::Browser.new
# b.goto 'twitter.com/'
# p ENV['TWITTER_OUTREACH_USERNAME']
# binding.pry
# b.text_field(name: "session[username_or_email]").set(ENV['TWITTER_OUTREACH_USERNAME'])
# b.text_field(name: "session[password]").set(ENV['TWITTER_OUTREACH_PASSWORD'])
# b.button(text: "Log in").click

# user = "@Acec23"
# b.goto "https://twitter.com/#{user}"
# b.button(id: "menu-0").click
# b.button(text: "Send a Direct Message").click
# b.div(class: "DirectMessage-text").text
# binding.pry
# t.click
# t.set 'happy'
# binding.pry

# @szaman