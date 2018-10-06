require 'watir'
require 'pry'
require 'firebase'
require_relative './twitter_messenger'



handles = File.readlines('twitter_handles.txt').map(&:strip)

messenger = TwitterMessenger.new
messenger.create_browser_and_login
messenger.message_everyone_on_page
#messenger.follow_every_trader_on_page

# binding.pry
# handles.each do |handle|
#   direct_message_enabled = messenger.direct_message_enabled?(handle)
#   if direct_message_enabled
#     File.open("direct_message_enabled.txt", "a") {|f| f.write("#{handle}\n") }
#   end
#   puts "#{handle}: direct message #{direct_message_enabled ? "" : "NOT"} enabled"
#   sleep(2)
# end
