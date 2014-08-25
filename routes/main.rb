class Rap < Sinatra::Base
  get '/assets/css/:file' do |filename|
    content_type "text/css"
    scss "scss/#{filename.gsub('.css', '')}".to_sym
  end
  get '/rules_football' do
    haml :rules_football
  end
  get '/rules_basketball' do
    haml :rules_basketball
  end
  namespace '/' do |r|
    before do
      @user_id = (session['user_id'] || request.cookies['user_id'] || '')
      @current_user = User.find(@user_id)

      @base_url = '/'
    end
    get do
      if @current_user
        @teams = Team.all
        @seasons = @current_user.seasons
        redirect "/#{@teams.first.code}/" if @current_user.active_seasons.length == 1 and @teams.select(&:active?).length == 1
        haml :main
      else
        haml :welcome
      end
    end
    get 'signup/:team_code' do |code|
      @current_user.signup_for_team(Team.find_by(code: code))
      redirect "/#{code}/"
    end
    namespace ':team_code/' do
      before do
        pass if request.path['auth'] or request.path['assets']
        @current_user = User.find(@user_id)
        @team = Team.find_by(code: params[:team_code])
        @season = @current_user.seasons.find_by(team: @team)
        # redirect '/' unless @current_user
        # session['team'] = team_code
      end
      get do
        # {verb: request.request_method, path: r.full_path_info, params: r.params, session: session}.to_json
        haml :team
      end
      get 'rules' do
        haml "rules_#{@team.sport}".to_sym
      end
      namespace 'standings' do
        get do
          @team = Team.find_by(code: params[:team_code])
          haml :standings
        end
        get '/:user_id' do |user_id|

        end
      end
      namespace 'games/' do
        get do
          @games = @team.games
          # @reservations = @user.reservations(params.verify)
          haml :games
        end
        namespace ':game_number/' do
          before do
            @team = Team.find_by(code: params[:team_code])
            @season = @current_user.seasons.find_by(team: @team)
            @game = @team.game_number(params[:game_number].to_i)
          end
          get do
            @mobile = request['X_MOBILE_DEVICE']
            @current_user = User.find(@user_id)
            @team = Team.find_by(code: params[:team_code])
            @season = @current_user.seasons.find_by(team: @team)
            @game = @team.game_number(params[:game_number].to_i)
            haml :game
          end
          post do
            @picks = params[:picks]
            @pickset = @season.picksets.find_or_create_by(game: @game)
            @pickset.update_picks(@picks, params[:total])
            # @season.picksets.create(performance_ids: @picks, game: @game)
            redirect request.referrer
          end
          get 'stats' do
            # stats from game
          end
          get 'results' do
            # results from game => points for picksets, rankings
          end
        end
      end

      namespace 'players/' do
        get do
          {verb: request.request_method, path: r.full_path_info, params: r.params}.to_json
        end
        get ':jersey' do |jersey|
          # @player = @team.find_by(jersey: jersey)
        end
      end
    end
  end
end

