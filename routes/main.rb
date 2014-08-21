class Rap < Sinatra::Base
  get '/assets/css/:file' do |filename|
    # puts "scss/#{filename.gsub('.css', '')}"
    content_type "text/css"
    scss "scss/#{filename.gsub('.css', '')}".to_sym
    # 'helo'
  end
  namespace '/' do |r|
    before do
      # set_view_subdir "mobile" if request['X_MOBILE_DEVICE']
      @user_id = (session['user_id'] || request.cookies['user_id'] || '')
      session['return_url'] = nil
      @current_user = User.find(@user_id)
      @base_url = '/'
    end
    get do
      @teams = Team.all
      haml :main
    end
    namespace ':team_code/' do |team_code|
      before do
        @team = Team.find_by(code: team_code)
        session['team'] = team_code
      end
      get do
        # {verb: request.request_method, path: r.full_path_info, params: r.params, session: session}.to_json
        haml :team
      end
      namespace 'standings/' do
        get do
          "currents standings and overview"
        end
        get ':user_id' do |user_id|

        end
      end
      namespace 'games/' do
        get do
          @games = @team.games
          # @reservations = @user.reservations(params.verify)
          {verb: request.request_method, path: r.full_path_info, params: r.params}.to_json
          haml :games
        end
        namespace ':game_number/' do |game_number|
          before do
            @game = @team.game_number(game_number.to_i)
          end
          get do
            haml :game
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

