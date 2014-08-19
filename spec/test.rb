require_relative '../models/init'
require 'csv'
require 'json'
require 'yaml'
b_hash = {
  sport:      :basketball,
  year:       2015,
  # code:       '',
  url_roster: 'http://www.arizonawildcats.com/SportSelect.dbml?DB_OEM_ID=30700&SPID=127128&SPSID=750096',
  url_ics:    'http://www.arizonawildcats.com/export/outlook.dbml?SPSID=750027&SPID=127113&DB_LANG=C&db_oem_id=30700&season=2014&sport_id=127128',
}

f_hash = {
  sport:      :football,
  year:       2014,
  # code:       '',
  url_roster: 'http://www.arizonawildcats.com/SportSelect.dbml?SPSID=750028&SPID=127113&DB_OEM_ID=30700&Q_SEASON=2014',
  url_ics:    'http://www.arizonawildcats.com/export/outlook.dbml?SPSID=750089&SPID=127128&DB_LANG=C&db_oem_id=30700&season=2014&sport_id=127113',
}

reset = false
reset = true

def price_from_post(post_url)
  # import pricing from board post (or maybe just the text? idk)
end
def score_from_post(post_url)
  # import scoring from board post
end

def user_flow(reset = nil)
  auth = ['prh', 'goazcats']
  # auth = nil
  if reset
    User.all.destroy
    Season.all.destroy
    Pickset.all.destroy
  else
    # u = User.find_or_create_by
    u = User.new(email: 'p@r.h', password: 'gocats', password_confirmation: 'gocats')
    puts u.inspect
  end
end

def admin_flow(reset = true)

  f_hash = {
    sport:      :football,
    year:       2014,
    # code:       '',
    url_roster: 'http://www.arizonawildcats.com/SportSelect.dbml?SPSID=750028&SPID=127113&DB_OEM_ID=30700&Q_SEASON=2014',
    url_ics:    'http://www.arizonawildcats.com/export/outlook.dbml?SPSID=750089&SPID=127128&DB_LANG=C&db_oem_id=30700&season=2014&sport_id=127113',
  }
  # if reset
    Team.all.destroy
    Game.all.destroy
    Player.all.destroy
    Performance.all.destroy
  # else
    t = Team.find_or_create_by(f_hash)
    t.open
    puts t.games.count
    puts t.players.count
    g = t.next_game
    g.prepare
    prices = g.performances.sample(10).map { |p| [p._id, rand(2..35)]  }
    # puts prices.map(&:inspect)
    g.price(prices)
    g.clean

    # t.prepare_game


    # t.clean_game
  # end
end
module Flows
  class Data
    class << self
      def clear
        Flows::Admin.clear
        Flows::Person.clear
      end
      def team_b
        {
          sport:      :basketball,
          year:       2015,
          # code:       '',
          url_roster: 'http://www.arizonawildcats.com/SportSelect.dbml?DB_OEM_ID=30700&SPID=127128&SPSID=750096',
          url_ics:    'http://www.arizonawildcats.com/export/outlook.dbml?SPSID=750027&SPID=127113&DB_LANG=C&db_oem_id=30700&season=2014&sport_id=127128',
        }
      end
      def team_f
        {
          sport:      :football,
          year:       2014,
          # code:       '',
          url_roster: 'http://www.arizonawildcats.com/SportSelect.dbml?SPSID=750028&SPID=127113&DB_OEM_ID=30700&Q_SEASON=2014',
          url_ics:    'http://www.arizonawildcats.com/export/outlook.dbml?SPSID=750089&SPID=127128&DB_LANG=C&db_oem_id=30700&season=2014&sport_id=127113',
        }
      end
      def team_f13
        {
          sport:      :football,
          year:       2013,
          # code:       '',
          url_roster: 'http://www.arizonawildcats.com/SportSelect.dbml?SPSID=750028&SPID=127113&DB_OEM_ID=30700&Q_SEASON=2013',
          url_ics:    'http://www.arizonawildcats.com/export/outlook.dbml?SPSID=750089&SPID=127128&DB_LANG=C&db_oem_id=30700&season=2014&sport_id=127113',
        }
      end
      def user_info
        {
          email: 'p@r.h', password: 'gocats', password_confirmation: 'gocats'
        }
      end
    end
  end
  class Admin
    class << self
      def clear
        Team.all.destroy
        Game.all.destroy
        Player.all.destroy
        Performance.all.destroy
        ScoringGuide.all.destroy
      end
      def add_scoring
        # j = JSON.parse(File.read('scoring.json'))
        y = YAML::load(File.read('scoring.yaml'))
        # puts y.first.inspect
        # j.map!{ |h| h.merge(effective_at: Time.now, expires_at: Time.now) }
        # File.write('scoring.yaml', j.to_yaml)
        y.each { |h| ScoringGuide.create(h) }
      end
      def team
        @@t ||= Team.find_by(Flows::Data.team_f13)
      end
      def team_create
        @@t = Team.create(Flows::Data.team_f13)
      end
      def team_open
        team.open
      end
      def next_game
        team.next_game
      end
      def game_prepare
        team.next_game.prepare
      end
      def game_price
        prices = next_game.performances.sample(15).map { |p| [p._id, rand(2..15)]  }
        next_game.price(prices)
      end
      def game_open
        team.next_game.open
      end
      def game_score(data)
        team.next_game.score(data)
      end
      def game_clean
        next_game.clean
      end
    end
  end
  class Person
    class << self
      def clear
        User.all.destroy
        Season.all.destroy
        Pickset.all.destroy
      end
      def default_user
        @@u ||= User.find_by(Flows::Data.user_info)
      end
      def user_login(params)
        User.find_by(name: params[:name])
      end
      def user_create(params = Flows::Data.user_info)
        @@u = User.create(params)
      end
      def season(user = default_user)
        @@season ||= user.seasons.first
      end
      def season_create(team, user = default_user)
        @@season = user.signup_for_team(team)
      end
      def pickset_choose
        season.team.next_game.performances.sample(15).map(&:_id)
      end
      def pickset_create(performances, user = default_user)
        # p = Performance.find(performances)
        user.picksets.create(performance_ids: performances)
      end
    end
  end
end
# stats = CSV.table(path, headers: true, converters: :numeric, header_converters: :symbol)
# puts stats.first.to_hash#.headers # => keys

# for non-empty column style
# arr = stats.first.to_hash.chunk {|k,v| k != 'number' and Integer === v }.to_a.map(&:last)
# h = {identity: Hash[arr.first], stats: arr.last.map(&:last)}
# puts h
# puts Hash[arr.first].inspect
# puts arr.last.map(&:last).inspect
# exit
# for empty column style
# puts stats.first.to_hash.chunk {|k,v| k.nil? }.to_a[0].inspect
# puts stats.first.to_hash.chunk {|k,v| k.nil? }.to_a[1].inspect
# puts stats.first.to_hash.chunk {|k,v| k.nil? }.to_a[2].inspect
# puts stats.first.inspect
# puts Hash[stats.first.to_a[0..sep-1]].inspect
# puts stats.first.fields[sep+1..-1].inspect


path = 'stats.csv'
stats = CSV.read(path, headers: true, converters: :numeric)
sep = stats.first.index(nil) # => values
data = stats.map do |row|
  {identity: Hash[row.to_a[0..sep-1]], stats: row.fields[sep+1..-1]}
end
# puts data.inspect
# exit
# puts h
# p = Player.find_by(h[:identity])
# puts p.inspect
# exit

# stackprof this tmw...
# puts ScoringGuide.where(sport: :football).count
# puts ScoringGuide.current(:football)
# puts ScoringGuide.all.map(&:sport).inspect
# exit
Flows::Data.clear
Flows::Admin.add_scoring
# exit
# puts Flows::Admin.team.inspect
Flows::Admin.team_create unless Flows::Admin.team
Flows::Admin.team_open
t = Team.current.first
u = Flows::Person.user_create unless Flows::Person.default_user
puts t._id.to_s
Flows::Person.season_create(t._id.to_s)
Flows::Admin.game_prepare
Flows::Admin.game_price
Flows::Admin.game_open
perfs = Flows::Person.pickset_choose
ps = Flows::Person.pickset_create(perfs)
Flows::Admin.game_score(data)
# add game stats
# game.score
# picksets.rank
# puts ps.inspect


# puts u.seasons.inspect



# user_flow
# admin_flow(false)
