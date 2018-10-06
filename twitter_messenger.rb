require_relative './has_been_messaged_db'

class TwitterMessenger

  INTRO_MESSAGE_FROM_NASDAQ_COWBOY = "Hey thanks for following me! I'm just reaching out to let you know I've started a new YouTube show for stock traders. The show is called Behind The Bid @behindthebid, and it is livestreamed every morning at 8:20am ET, where I cover the news behind the premarket movers and the sentiment on Twitter (bullish or bearish?). It's a short show, we usually we spend 1 minute per stock (8-9 stocks total, so it's rapid fire!) and it is livestreamed an hour before the market opens so you have plenty of time to do your own due diligence before the trading day starts. I'd love for you to check it out and give me any constructive criticism you have!"
  
  INTRO_MESSAGE_FROM_BEHINDTHEBID = "Hey thanks for following me!  Behind The Bid is a YouTube show for stock traders, and it is livestreamed every morning at 8:20am ET, where I cover the news behind the premarket movers and the sentiment on Twitter (bullish or bearish?). It's a short show, we usually we spend 1 minute per stock (8-9 stocks total, so it's rapid fire!) and it is livestreamed an hour before the market opens so you have plenty of time to do your own due diligence before the trading day starts.  I'd love for you to check it out and give me any constructive criticism you have!"
  DIRECT_MESSAGE_INPUT_CLASSES = ["DMComposer-editor", "tweet-box", "rich-editor", "js-initial-focus", "is-showPlaceholder"]
  
  HELLO_MESSAGE = "Hello there! I see that you have an interest in trading stocks. I'm reaching out to let you know that I've started a new YouTube show for stock traders. The show is called Behind The Bid @behindthebid, and it is livestreamed every morning at 8:20am ET, where I cover the news behind the premarket movers and the sentiment on Twitter (bullish or bearish?). It's a short show, we usually we spend 1 minute per stock (8-9 stocks total, so it's rapid fire!) and it is livestreamed an hour before the market opens so you have plenty of time to do your own due diligence before the trading day starts. I'd love for you to check it out and give me any constructive criticism you have!"
  PING_MESSAGE = "hey man, how's your trading going?"
  attr_reader :browser
  START_URL = 'twitter.com/investorslive/followers'

  #@szman @axforex: does not have trading profile
  START_AT_HANDLE = nil #"@BarBreakTrader".strip
  #@investorslive: @BarBreakTrader

  def initialize()
    @browser = nil
    @db = HasBeenMessagedDb.new
    @messages_sent = 0
    @last_index_processed = 0
    @follows_added = 0
    @still_looking_for_start_handle = true
  end

  def create_browser_and_login
    @browser = Watir::Browser.new
    @browser.goto 'twitter.com/'
    @browser.text_field(name: "session[username_or_email]").set(ENV['TWITTER_OUTREACH_PASSWORD'])
    @browser.text_field(name: "session[password]").set(ENV['TWITTER_OUTREACH_PASSWORD'])
    @browser.button(text: "Log in").click
  end

  def message_everyone_on_page
    @browser.goto START_URL
    sleep 1
    while true
      message_everyone_on_current_page
      scroll_down_until_we_add_1
    end
  end

  def follow_every_trader_on_page
    @browser.goto START_URL
    sleep 1
    while true
      follow_every_trader_on_current_page
      scroll_down_until_we_add_1
      if @follows_added > 300
        break
      end
    end
  end

  def scroll_down_until_we_add_1
    starting_users = @browser.divs(class: "ProfileCard-content").length
    while true
      @browser.driver.execute_script("window.scrollBy(0,2000)")
      sleep 1
      current_users = @browser.divs(class: "ProfileCard-content").length
      if current_users > starting_users + 1
        break
      end
    end
  end

  def follow_every_trader_on_current_page
    while @last_index_processed < @browser.divs(class: "ProfileCard-content").length
      follow_div_at_index(@last_index_processed)
      @last_index_processed += 1
    end
  end

  def follow_div_at_index(index)
    d = @browser.divs(class: "ProfileCard-content")[index]
    if !d.text.match(/@.+\b/)
      binding.pry
    end
    handle = d.text.match(/@.+\b/)[0].strip

    if START_AT_HANDLE && @still_looking_for_start_handle
      if handle == START_AT_HANDLE
        @still_looking_for_start_handle = false 
      else
        puts "skipping #{handle}"
        return
      end
    end

    has_trading_profile = !d.text.downcase.match(/trad|stock|financ|capital|invest/).to_s.strip.empty?
    if !has_trading_profile
      puts "#{handle}: does not have trading profile"
      return
    end

    if d.span(text: "Follow").present?
      follow_button = d.span(text: "Follow")
      @browser.execute_script('arguments[0].scrollIntoView();', follow_button)
      @browser.execute_script('window.scrollBy(0, -200);')
      sleep 0.3
      follow_button.click
      puts "Now following #{handle}, number follows added #{@follows_added}"
      @follows_added += 1
      sleep 5
    end

  end


  def message_everyone_on_current_page
    while @last_index_processed < @browser.divs(class: "ProfileCard-content").length
      message_div_at_index(@last_index_processed)
      @last_index_processed += 1
    end
  end

  def message_div_at_index(index)
    d = @browser.divs(class: "ProfileCard-content")[index]
    if !d.text.match(/@.+\b/)
      binding.pry
    end
    handle = d.text.match(/@.+\b/)[0].strip
    if @db.already_messaged?(handle)
      puts "already in db #{handle}"
      return
    end
    has_trading_profile = !d.text.downcase.match(/trad|stock/).to_s.strip.empty?
    has_trade_in_handle = !handle.downcase.match(/trad|stock/).to_s.strip.empty?
    if !has_trading_profile && !has_trade_in_handle
      puts "#{handle}: does not have trading profile"
      return
    end

    button = d.button(class: ["user-dropdown", "dropdown-toggle", "js-dropdown-toggle", "js-link", "js-tooltip", "btn", "plain-btn", "small-user-dropdown"])
    button.click
    has_direct_message_enabled = d.button(text: "Send a Direct Message").present?
    if has_direct_message_enabled
      d.button(text: "Send a Direct Message").click
      sleep 1
      if !have_i_sent_message_before
        @browser.div(class: DIRECT_MESSAGE_INPUT_CLASSES).set(PING_MESSAGE)
        @browser.button(class: ["EdgeButton", "EdgeButton--primary", "tweet-action"]).click
        sleep(1)
        if direct_message_has_error?
          binding.pry
          puts "DIRECT MESSAGE HAS ERROR!!!****"
          return
        end
        @browser.element.send_keys(:escape)
        File.open('wrote_message_to.txt', "a") {|f| f.write("#{handle}\n") }
        puts "#{handle} sent message!, total messages sent #{@messages_sent}"
        @messages_sent += 1
        sleep(1)
      else
        @browser.element.send_keys(:escape)
        sleep 1
      end
    end
    @db.set_has_been_messaged(handle)
    sleep 1
  end

  def send_intro_message(handle)
    
    @browser.goto "https://twitter.com/#{handle}"
    #@browser.button(id: "menu-0").click
    right_side_action_button.click 
    if !direct_message_button.present?
      puts "#{handle} has no direct message link!"
      return
    end
    @browser.button(text: "Send a Direct Message").click
    sleep(1)
    #has_sent_message = @browser.div(class: "DMActivity-notice").text.strip.length != 0
    sent_message_before = have_i_sent_message_before
    if !sent_message_before
      @browser.div(class: DIRECT_MESSAGE_INPUT_CLASSES).set(INTRO_MESSAGE_FROM_BEHINDTHEBID)
      @browser.button(class: ["EdgeButton", "EdgeButton--primary", "tweet-action"]).click
      sleep(1)
    end
    puts "#{handle} already sent message: #{sent_message_before}"
    #@browser.div(class: "DirectMessage-text").text
  end

  def direct_message_enabled?(handle)
    @browser.goto "https://twitter.com/#{handle}"
    right_side_action_button.click
    button_present = direct_message_button.present?
    add_or_remove_from_lists_button.click
    button_present
  end

  def have_i_sent_message_before
    @browser.div(class: "DirectMessage-text").exists? && @browser.div(class: "DirectMessage-text").text.strip.length != 0
  end

  def direct_message_has_error?
    @browser.div(class: ["DMNotice", "DMResendMessage", "DMNotice--error", "is-copyAllowed", "has-messageText"]).present?
  end

  def right_side_action_button
    browser.button(class: ["user-dropdown", "dropdown-toggle", "js-dropdown-toggle", "js-link", "js-tooltip", "btn", "plain-btn"])
  end

  def direct_message_button
    @browser.button(text: "Send a Direct Message")
  end

  def add_or_remove_from_lists_button
    @browser.button(text: "Add or remove from lists…")
  end
  #@browser.execute_script('window.scrollBy(0, -10);')

  #["EdgeButton","EdgeButton--secondary","EdgeButton--small","button-text","follow-text"]

end