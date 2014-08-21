class Rap < Sinatra::Base
  before do
    @js = []
    @css = []
  end

  namespace '/admin/' do
    before do
      @current_user = Admin.find(@user_id)   # => change to Admin.find(id)
      redirect '/' unless @current_user
      @base_url = '/admin/'
    end
    get do
      @teams = Team.all
      # list teams and create a new team
      # haml :index
      @content = {verb: r.env['REQUEST_METHOD'], path: request.path, params: params, note: 'admin area'}
      haml :'admin/main'
    end
    post 'teams' do
      # create team here
      if t = Team.find_by(year: params['year'], sport: params['sport'])
        t.update(params)
      else
        t = Team.create(params)
      end

      redirect "/admin/#{t.code}/"
    end
    namespace ':team_code/' do |team_code|
      before do
        @team = Team.find_by(code: team_code)
        @base_url << "#{@team.code}/"
      end
      get do
        haml :'admin/team'
      end
      post do
        # login
        # error handle for bad login
      end
      get 'open' do
        @team.open
        redirect request.referrer
      end
      get 'close' do
        @team.close
        redirect request.referrer
      end
      get 'finalize' do
        @team.finalize
        redirect request.referrer
      end
      get 'delete' do
        @team.delete
        redirect '/admin/'
      end
      namespace 'games/' do
        get do
          # @reservations = @user.reservations(params.verify)
          {verb: r.env['REQUEST_METHOD'], path: request.path, params: params}.to_json
        end
        namespace ':game_number/' do |game_number|
          before do
            @game = @team.game_number(game_number)
            @base_url << "games/#{@game.number}/"
          end
          get do
            haml :'admin/game'
          end
          get 'stats' do
            # file upload or maybe big form
            # google spreadsheet?

            # stats from game
          end
          get 'results' do
            # results from game => points for picksets, rankings
          end
          namespace 'status/' do
            get 'prepare' do
              @game.prepare
              redirect request.referrer
            end
            get 'price' do
              arr = params['ids'].zip(params['dol']).reject{ |_, d| d.empty? }
              # puts arr.map(&:inspect)
              @game.price(arr)
              redirect request.referrer
            end
            post 'price' do
              puts 'posted'
              # validate params['prices'] is a proper array
              # @prices = params['ids'].zip(params['dol'])
              # puts @prices.inspect
              # @prices.reject!{ |_, p| p.empty? }
              # puts @prices.inspect


              # @game.price(params['prices'])
              redirect request.referrer
            end
            get 'confirm' do
              @game.update_time(params['time'])
              redirect request.referrer
            end
            get 'open' do
              @game.open
              # notify people? make post on forum?
              redirect request.referrer
            end
            get 'lock' do
              # ensure that Time.now > @game.time
              @game.lock
              redirect request.referrer
            end
            get 'stats' do
              # stats = ra.params['file_upload'] or google spreadsheet
              path = 'stats.csv'
              stats = ScoringGuide.import_stats_csv(path)
              @game.score(stats) # ok i guess we'll score it too. if it's a file upload
              redirect request.referrer
            end
            get 'score' do
              # this will be separate if the stats are done by google sheet
              # otherwise these two can't be separated
              # @game.score(spreadsheet_data)
              redirect request.referrer
            end
            get 'finalize' do
              @game.update_standings
              redirect request.referrer
            end
            get 'next' do
              redirect request.referrer.gsub("games/#{@game.number}", "games/#{@game.number + 1}")
            end
          end
        end
      end
    end
  end
end
