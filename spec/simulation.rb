# Simulation
require_relative '../models/init'
require 'csv'
require 'json'
require 'yaml'
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
def clear
  Team.all.destroy
  Game.all.destroy
  Player.all.destroy
  Performance.all.destroy
  ScoringGuide.all.destroy
  ScoringGuide.all.destroy
  User.all.destroy
  Season.all.destroy
  Pickset.all.destroy
end
def add_scoring_guides
  y = YAML::load(File.read('scoring.yaml'))
  y.each { |h| ScoringGuide.create(h) }
end

clear         # empty db for clean run
puts "DB cleared @ #{Time.now}"
STDOUT.flush
Admin.create(name: 'prh', password: 'prh')
# admin => setup
add_scoring_guides                                    # => scoring guides added in advance
t = Team.find_by(team_f13) || Team.create(team_f13)   # => admin creates team
t.open                                                # => team is opened for signup
puts "admin setup done @ #{Time.now}"
STDOUT.flush

# users sign up
json_data = JSON.parse(File.read('data.json')) # => fake user info
Admin.create(name: 'admin', password: 'admin')
users = json_data['users'].map do |h|
  u = User.find_by(name: h['name']) || User.create(h)   # => user creates account
  team = Team.current.first._id           # => user looks up open teams and picks one (from web, using _id)
  u.signup_for_team(team)                 # => server signs up for season
  u
end
puts "user signup done @ #{Time.now}"
puts 'entering game loop'
STDOUT.flush

# i = 1
# t.games.length.times do |j|
3.times do |j|
  i = j + 1

  # # admin => getting a game ready to go
  g = t.next_game                 # => admin selects next games
  g = t.game_number(i)                 # => admin selects next games
  g.prepare                       # => admin prepares game (prices, confirm time)
  prices = g.performances.sample(15).map { |p| [p._id, rand(2..15)] } # [[_id, price],[_id, price],[_id, price]]
  g.price(prices)                 # => admin prices next game
  g.update_time(time = nil)       # => admin confirms game time
  g.open                          # => admin opens game for picks
  puts "#{g.opponent} admin prep  done @ #{Time.now}"
  t.reload
  STDOUT.flush

  gs = users.map do |u|            # user picking a game
    u.reload
    active = u.active_seasons     # => user is presented their active seasons # skip if length.one?
    season = active.first         # => user selects season
    # games, game = nil, nil
    games = season.open_games     # => user is presented games open for picking, season.open_games == season.team.open_games
    game  = games.last            # => user selects game
    picks = game.performances.sample(15).map(&:_id).map(&:to_s) # fake pick data [_id, _id, _id, ...]
    pick = season.picksets.create(performance_ids: picks, game: game, total: rand(30..70))       # => user submits picks
    game.opponent
  end
  puts "#{gs.uniq.first} user picks  done @ #{Time.now}"
  STDOUT.flush


  # # admin scoring / finalizing game
  path = 'stats.csv'                            # => admin uploads stats.csv
  stats = ScoringGuide.import_stats_csv(path)   # => stats file gets parses
  # g = t.next_game                               # => would normally be last_game (switched to avoid time-travel issues)
  g = t.game_number(i)                               # => would normally be last_game (switched to avoid time-travel issues)
  g.score(stats, rand(30..70))                   # => score the game
  g.update_standings                            # => update standings
  puts "#{g.opponent} admin score done @ #{Time.now}"
  STDOUT.flush
end
# puts t.game_number(i+1).inspect
