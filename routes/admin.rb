class Rap < Sinatra::Base
  before do
    @js = []
    @css = []
  end
  get '/admin' do
    redirect '/admin/'
  end
  namespace '/admin/' do
    before do
      @current_user = Admin.find(@user_id)   # => change to Admin.find(id)
      redirect '/' unless @current_user
      # @base_url = '/admin/'
      # puts @base_url
    end
    get do
      @teams = Team.all
      # list teams and create a new team
      # haml :index
      @content = {verb: request.request_method, path: request.path, params: params, note: 'admin area'}
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
    namespace ':team_code/' do
      before do
        @team = Team.find_by(code: params[:team_code])
        # @base_url << "#{@team.code}/"
      end
      get do
        @team = Team.find_by(code: params[:team_code])
        haml :'admin/team'
      end
      post do
        # login
        # error handle for bad login
      end
      get 'standings' do
        @team = Team.find_by(code: params[:team_code])
        haml :'admin/standings'
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
          {verb: request.request_method, path: request.path, params: params}.to_json
        end
        namespace ':game_number/' do
          before do
            @team = Team.find_by(code: params[:team_code])
            @game = @team.game_number(params[:game_number])
            # @base_url << "games/#{@game.number}/"
          end
          get do
            @team = Team.find_by(code: params[:team_code])
            @game = @team.game_number(params[:game_number])
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
            post 'confirm' do
              @game.update_time(nil)
              redirect request.referrer
            end
            get 'open' do
              @game.open
              if (ENV['board_autopost'].downcase == 'true' or params['board_post'])
                p = Forum::Post.new(:prices, game: @game)
                p.post
              end
              # notify people? make post on forum?
              redirect request.referrer
            end
            get 'lock' do
              # ensure that Time.now > @game.time
              @game.lock
              redirect request.referrer
            end
            get 'stats' do # csv template download
              @team = Team.find_by(code: params[:team_code])
              content_type 'application/csv'
              attachment "RAP-#{@team.code}-#{@game.number}.csv"
              @game.stats_template
            end
            post 'stats' do
              # puts params['stats'].inspect
              stats = ScoringGuide.import_stats_csv(params[:stats][:tempfile].path)
              @game.score(stats, params[:total])
              @game.update_standings
              if (ENV['board_autopost'].downcase == 'true' or params['board_post'])
                p = Forum::Post.new(:results, game: @game)
                p.post
              end
              redirect request.referrer
            end
            get 'post_results' do
              p = Forum::Post.new(:results, game: @game)
              p.post
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
              p = Forum::Post.new(:results, game: @game)
              p.post
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
