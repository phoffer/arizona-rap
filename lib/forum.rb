require 'rest_client'
require 'nokogiri'
module Forum
  module Base
    def self.login
      login_url = 'http://forum.prodigaleyelid.com/ucp.php?mode=login'
      login_data = {  'username' => ENV['board_username'],
                      'password' => ENV['board_password'],
                      'autologin' => true,
                      'viewonline' => true,
                      'redirect' => 'index.php',
                      'login' => 'Login'
                    }
      response = RestClient.post(login_url, login_data)
      response.cookies
    end
    def self.post(url, form_data)
      cookies = login
      doc = Nokogiri::HTML(RestClient.get(url, {cookies: cookies}).body)
      form_token = doc.xpath('//*[@id="options-panel"]/div/input[2]')
      creation_time = doc.xpath('//*[@id="options-panel"]/div/input[1]')
      lastclick = doc.xpath('//*[@id="postform"]/div[2]/div/fieldset/input[1]')
      form_data['form_token']    = form_token.attr('value').to_s
      form_data['creation_time'] = creation_time.attr('value').to_s
      form_data['lastclick']     = lastclick.attr('value').to_s
      # puts form_data.inspect
      sleep 3
      response2 = RestClient.post(
        url,
        form_data,
        {:cookies => cookies}
      )
    end
  end
  class Post
    def initialize(type, **info)
      @type = type
      @game = info[:game]
    end
    def post
      Forum::Base.post(self.class.url(@game.team.sport), self.data)
    end
    def data
      @data ||= self.class.params.merge(self.send("content_#{@type}"))
    end
    private
    def content_prices
      subject = "***#{@game.opponent} RAP Prices***"
      message = "DO NOT EDIT YOUR PICKS!\n\n"
      message << @game.performances.gt(price: 1).order_by(price: :desc).map { |p| "#{p.player.last}, #{p.player.first} $#{p.price}" }.join("\n")
      message << "\n\nANYONE ELSE $1 (pick an individual player for $1... not all the remaining players for $1)\n\nPM me if you have any questions/concerns. Good luck!\n\nBear Down, Beat #{@game.opponent}!"
      {subject: subject, message: message}
    end
    def content_results
      subject = "***#{@game.opponent} RAP Results***"
      message = "[b]Players:[/b]\n"
      message << @game.performances.gt(points: 0).order_by(points: :desc).map { |p| "#{p.player.last}, #{p.player.first} #{p.points}" }.join("\n")
      message << "\n\n\n[b]Posters:[/b]\n"
      message << @game.picksets.order_by(rank: :asc).map { |p| "#{p.season.user.name} #{p.points}" + (p.rank_points > 0 ? " [b]#{p.rank_points}[/b]" : '') }.join("\n")
      message << "\n\n\n[b]Overall Standings:[/b]\n"
      message << @game.team.seasons.order_by(rank_points: :desc, points: :desc).map { |s| "#{s.user.name} #{s.rank_points}" }.join("\n")
      message << "\n\n\nDisclaimer: I'm human, I make mistakes. Please double-check my math and PM me if you find any discrepancies. You have until kick-off of the next game to register a complaint/question about this game.\n\n[b]Bear Down.[/b]"
      {subject: subject, message: message}
    end
    class << self
      def params
        {
          # 'subject' => 'Test subject line',
          # 'message' => "Just trying something new.\n\n\n",
          # 'lastclick' => '1408832590',
          'name' => 'Login',
          'preview' => 'Preview',
          'post' => 'Submit'
          # 'form_token' => 'a5ca42ae61a9019d3de049b5e0985d3b48aefef6',
          # 'creation_time' => '1408832590'
        }
      end
      def url(sport)
        hash = {football: 9, basketball: 8}
        hash = {football: 14, basketball: 14}
        "http://forum.prodigaleyelid.com/posting.php?mode=post&f=#{hash[sport]}"
      end
    end
  end
  class Message
    # stuff
  end
end
