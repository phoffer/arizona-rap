class User
  include Mongoid::Document
  include ActiveModel::SecurePassword
  include ActiveModel::MassAssignmentSecurity
  has_many :seasons

  field :name,            type: String
  field :email,           type: String
  field :cell,            type: String
  field :carrier,         type: String
  field :role,            type: Integer
  field :password_digest, type: String
  has_secure_password
  attr_protected :role
  index({ name: 1 }, { unique: true })

  # send code through phpBB message, basically login?id=BSON_ID
  # then set cookie if desired
  # allow to set password anyways if they want
  # or maybe this is a terrible complexity creep haha

  def signup_for_team(team)
    self.seasons.create(team: team)
  end
  def active_seasons
    self.seasons.select(&:active?)
  end
  def open_games
    self.active_seasons.map(&:open_games).flatten
  end
  def admin?
    false
  end

  class << self
    def authenticate(id, password)
      user = self.or({ email: id }, { name: id }).first and user.authenticate(password)
    end
  end
end

class Admin < User
  after_create do |user|
    user.update_attribute(:role, 0)
  end
  def admin?
    self.role.zero?
  end
end


class Season
  include Mongoid::Document
  belongs_to :user
  belongs_to :team
  has_many :picksets

  field :points,        type: Integer,  default: 0
  field :rank_points,   type: Integer,  default: 0
  field :rank,          type: Integer,  default: 100 # need to examine in case of ties

  def active?
    self.team.active?
  end
  def next_game
    self.team.current_game
  end
  def open_games
    self.team.open_games
  end
  def calculate_points
    self.points       = self.picksets.map(&:points).inject(:+)
    self.rank_points  = self.picksets.map(&:rank_points).inject(:+)
    self.save
  end

  class << self
  end
end

class Pickset
  include Mongoid::Document
  belongs_to :season
  belongs_to :game

  field :performance_ids,   type: Array,    default: -> {Array.new}
  # field :player_ids,        type: Array,    default: -> {Performance.find(self.performance_ids).map(&:player_id)}
  field :cost,              type: Integer,  default: -> {Performance.find(self.performance_ids).map(&:price).inject(:+)}
  field :points,            type: Integer,  default: 0
  field :rank,              type: Integer # need to examine this in case of ties...
  field :rank_points,       type: Integer,  default: 0
  field :total,             type: Integer,  default: 0
  field :difference,        type: Integer,  default: 1000
  include Mongoid::Timestamps
  after_create :validate_game
  scope :valid, ->(game) { lt(cost: 51, updated_at: game.time) }


  def update_picks(picks, total = nil)
    self.total = total if total
    self.performance_ids = picks
    self.cost = Performance.find(self.performance_ids).map(&:price).inject(:+)
    self.save
  end
  def players
    # Player.find(self.player_ids)
    self.performances.map(&:player)
  end
  def performances
    Performance.find(self.performance_ids)
  end
  def performances=(arr)
    self.update_attribute(:performance_ids, arr)
  end
  def score(sport, total)
    if self.cost > 50
      self.update_attributes(points: 0)
    else
      base = sport == :basketball ? 50 - self.cost : 0
      self.points = self.performances.map(&:points).inject(base, :+)
      self.difference = (self.total - total).abs
      self.save
    end
  end
  def validate_game
    return if self.game_id
    self.game = self.performances.first.game
    self.save
  rescue
    puts self.inspect
    raise
  end
end
class Team
  include Mongoid::Document
  has_many :games, dependent: :delete
  has_and_belongs_to_many :players
  has_many :seasons
  has_many :performances
  # has_many :seasons do
  #   def number(n)
  #     where(number: n).first
  #   end
  # end

  field :sport,       type: Symbol
  field :year,        type: Integer,  default: -> {Time.now.year}
  field :code,        type: String,   default: -> {"#{self.year}#{self.sport.to_s.first.upcase}"}
  field :url_roster,  type: String
  field :url_ics,     type: String
  field :google_doc,  type: String
  field :status_code, type: Integer,  default: 1

  index({ year: 1, sport: 1 }, { unique: true })

  after_create :import_games
  after_create :import_players

  scope :current,   -> { where(status_code: 1) }
  scope :active,    -> { lt(status_code: 3) }
  scope :finished,  -> { where(status_code: 3) }

  def status(n = self.status_code)
    %w{created open closed final}[n]
  end
  def status_next
    self.status(self.status_code + 1)
  end

  def import_games
    return false if self.games.exists? || self.url_ics.nil?
    self.games.concat(Game.from_ics(self.url_ics))
  end
  def import_players
    return false if self.players.exists? || self.url_roster.nil?
    self.players.concat(Player.from_roster(url_roster))
  end
  def prepare_game(parameters = nil)
    # game.id or game.number or ???
    (Game.find_by(parameters) or self.next_game).prepare
  end
  def clean_game(parameters = nil)
    (Game.find_by(parameters) or self.last_game).clean
  end
  def last_game
    self.games.lt(time: Time.now).first
  end
  def current_game
    self.games.between(time: (Time.now - 28*3600)..(Time.now + 120*3600)).first
  end
  def open_games
    self.games.select(&:open?)
  end
  def game_number(n)
    self.games.where(number: n.to_i).first
  end
  def next_game
    self.games.gt(time: Time.now).first
  end
  def open
    self.update_attribute(:status_code, 1)
  end
  def close
    self.update_attribute(:status_code, 1)
  end
  def finalize
    # update rankings
    self.update_attribute(:status_code, 1)
  end
  def active?
    self.status_code < 3
  end
  def finalized?
    self.status_code == 8
  end
  def update_season_rankings
    self.seasons.map(&:calculate_points)
    self.seasons.order_by(rank_points: :desc, points: :desc).each_with_index {|s, i| s.update_attribute(:rank, i+1) }
  end
  def rankings
    self.seasons.order_by(rank: :asc, points: :desc)
  end
  class << self
    def webpage_of_schedules
      'http://www.arizonawildcats.com/export/export.dbml?SPSID=750027&SPID=127113&DB_LANG=C&DB_OEM_ID=30700'
    end
  end
end
class Game
  include Mongoid::Document
  has_many :performances
  has_many :picksets
  belongs_to :team

  field :opponent,      type: String
  field :time,          type: Time
  field :status_code,   type: Integer,  default: 0
  field :number,        type: Integer # => game number, i.e. (1..13) or (1..40)
  # field :points,        type: Integer # this is the sum of all point gained by players
  # field :cost,          type: Integer
  field :ics_id,        type: String
  field :total,         type: Integer

  default_scope -> { asc(:number) }


  def status(n = self.status_code)
    %w{created prepared priced confirmed open locked stats scored final next}[n]
  end
  def status_next
    self.status(self.status_code + 1)
  end
  def valid_picksets
    self.picksets.valid(self)
  end
  def prepare
    return if self.performances.exists?
    ids = self.team.players.map{ |player| player.performances.create }.map(&:_id)
    self.performance_ids = ids
    self.team.update_attribute(:performance_ids, self.team.performance_ids + ids)
    # self.team.performances.concat(self.team.players.map{ |player| player.performances.create })
    self.inc(status_code: 1)
  end
  def price(arr = nil)
    if status_code >= 4 || arr.nil?
      return false
    elsif status_code >= 2
      arr.each do |id, price|
        self.performances.find(id).update_attribute(:price, price.to_i)
      end
    elsif status_code == 1
      arr.each do |id, price|
        next if price.to_i == 1 # modify process to not even pass these ones
        self.performances.find(id).update_attribute(:price, price.to_i)
      end
      self.inc(status_code: 1)
    end
  end
  def scoring_guide
    ScoringGuide.current(self.team.sport)
  end
  def stats_template
    scoring = scoring_guide.key.keys
    CSV.generate do |csv|
      csv << %w{number last first} + [nil] + scoring
      self.performances.order_by(price: :desc).map{ |p| csv << [p.player.number, p.player.last, p.player.first, nil] + Array.new(scoring.length) }
    end
  end
  def google_data
    data_source = self.season.spreadsheet
    data = 1 # worksheet name = self.number
    # return data from here
  end
  def update_data
    return false unless self.status_code.between?(4,5)
    # verify google data is available
    self.update_attribute(:status_code, 6)
  end
  def score(data = nil, total = 0)
    return false unless self.status_code.between?(4,5)
    self.update_attribute(:total, total.to_i)
    points_arr = self.scoring_guide.points
    data.map do |hash|
      perf = Player.find_by(hash[:identity]).performances.find_by(game: self._id)
      perf.score(hash[:stats], points_arr)
    end
    self.scoring_guide.score_picksets(self.picksets, total.to_i)
    # self.clean
    self.update_attribute(:status_code, 7)
  end
  def update_standings
    return false unless self.status_code == 7
    self.team.update_season_rankings
    self.inc(status_code: 1)
  end
  def update_time(time = nil)
    time ||= self.time
    self.update_attributes(time: time, status_code: 3) if self.status_code == 2
  end
  def clean
    self.performances.destroy_all(points: 0)
  end
  def open # need to update time somewhere
    self.inc(status_code: 1) if self.status_code == 3
  end
  def lock
    self.inc(status_code: 1) if self.status_code == 4
  end
  def status_public
    case
    when self.status_code < 4
      :notready
    when (self.status_code == 4 && self.time > Time.now)
      :open
    when self.status_code == 8
      :final
    else
      :closed
    end
  end
  def notready?
    self.status_code < 4
  end
  def open?
    self.status_code == 4
  end
  def closed?
    self.status_code > 4 or self.time < Time.now
  end
  def final?
    self.status_code == 7
  end
  def rankings
    self.picksets.order_by(rank: :asc, created_at: :asc)
  end

  class << self
    def from_ics(url)
      array_from_ics(url).map { |h| Game.create(h) }
    end
    def hash_from_event(e)
      {
        opponent:     e.summary.split('vs. ').last.split(' -').first,
        time:         e.dtstart.to_time,
        ics_id:       e.uid
      }
    end
    def array_from_ics(url)
      events = Icalendar::Parser.new(open(url), false).parse.first.events
      events.map { |e| hash_from_event(e) }.sort_by{ |h| h['time'] }.reverse.each_with_index.map { |e, i| e.merge(number: i+1) }
    end
  end
end
class Player
  include Mongoid::Document
  has_many :performances
  has_and_belongs_to_many :teams

  field :number,      type: Integer # => jersey number for lookup. will require (o|d) for football. or maybe?
  field :first,       type: String
  field :last,        type: String
  field :position,    type: String # => {o,d,s(pecial teams)} or {actual positions?}
  field :year,        type: String
  field :home,        type: String

  field :group,       type: String # => (o|d) for jersey lookup

  def points_in_team(team)
    perfs = self.performances.where(team: team)
    perfs.map(&:points).inject(:+) / perfs.length
  end
  def price_in_team(team)
    perfs = self.performances.where(team: team)
    perfs.map(&:price).inject(:+) / perfs.length
  end
  def team_points_price(team)
    games = team.games.gt(status_code: 6).map(&:_id)
    perfs = self.performances.in(game_id: games)
    n = [perfs.length, 1].max
    [perfs.map(&:points).inject(:+) / n, perfs.map(&:price).inject(:+) / n]
  end


  class << self
    def from_roster(url)
      array_from_roster(url).map do |h|
        p = Player.find_or_create_by(first: h[:first], last: h[:last])
        p.update_attributes(h) and p
      end
    end
    def hash_from_player_row(noko_row)
      {
        number:       noko_row.elements[0].children.last.content.strip.to_i,
        first:        noko_row.elements[1].children.children.first.content.split(', ').last,
        last:         noko_row.elements[1].children.children.first.content.split(', ').first,
        position:     noko_row.elements[2].children.last.content.strip,
        # height:       noko_row.elements[3].children.last.content.strip,
        year:         noko_row.elements[5].children.last.content.strip.chomp('.'),
        # weight:       noko_row.elements[4].children.last.content.strip.to_i,
        home:         noko_row.elements[6].children.last.content.strip,
      }
    end
    def array_from_roster(url)
      doc = Nokogiri::HTML(open(url))
      rows = doc.css('#roster-table tr')
      header = rows.shift
      # puts rows.map { |r| hash_from_player_row(r) }.map(&:inspect)
      rows.map { |r| hash_from_player_row(r) }
    end
  end
end
class Performance
  include Mongoid::Document
  belongs_to :game
  belongs_to :player
  belongs_to :team
  # belongs_to :pickset => only relevant on pickset.performances

  field :price,     type: Integer,  default: 1
  field :stats,     type: Array
  field :points,    type: Integer,  default: 0

  # after_create do |p|
  #   p.game.team
  # end

  def updates_stats(arr)
    self.update_attribute(:stats, arr)
  end
  def score(stats = self.stats, scoring_arr)
    self.stats = stats
    # self.points = scoring_guide.calculate(stats)
    self.points = stats.zip(scoring_arr).inject(0) { |sum, arr| sum + (arr.first || 0) * arr.last }
    self.save
  end
end
class ScoringGuide
  include Mongoid::Document

  field :sport,         type: Symbol
  field :tiebreakers,   type: Hash,   default: -> { {'points' => 'desc', 'created_at' => 'asc'} }
  field :key,           type: Hash
  field :effective_at,  type: Time
  field :expires_at,    type: Time
  include Mongoid::Timestamps
  after_create { |sg| sg.update_attribute(:sport, sg.sport.intern) }

  def points
    self.key.values
  end
  def score_performances(performances, data)
    # score performances
  end
  def score_picksets(picksets, total)
    picksets.each { |p| p.score(self.sport, total) }
    case sport
    when :football
      # rank football picksets
    when :basketball
      # rank basketball picksets
    end
    # picksets.select{ |p| p.cost > 50 }.each{ |p| p.update_attribute(:points, 0) }
    order = picksets.order_by(self.tiebreakers)
    order.each_with_index do |p, i|
      rank_points = i.between?(0,19) ? 20-i : 0
      p.update_attributes(rank: i+1, rank_points: rank_points)
    end
  end
  class << self
    def current(sport)
      where(sport: sport).lt(effective_at: Time.now).gt(expires_at: Time.now).first
    end
    def import_stats_csv(path)
      # path = 'stats.csv'
      stats = CSV.read(path, headers: true, converters: :numeric)
      sep = stats.first.index(nil) # => empty column
      stats.map do |row|
        {identity: Hash[row.to_a[0..sep-1]], stats: row.fields[sep+1..-1]}
      end
    end
  end
end

