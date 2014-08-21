require 'roda'
class RodaApp < Roda
  route 'main' do |r|
    set_view_subdir "mobile" if r.env['X_MOBILE_DEVICE']
    r.session['return_url'] = nil
    # user_id = (r.session['user_id'] || r.cookies['user_id'] || '')
    @current_user = User.find(@user_id)
    @base_url = '/'
    r.root do
      @teams = Team.all.to_a
      view :main
    end
    r.on ':team_code' do |team_code|
      @team = Team.find_by(code: team_code)
      puts @team
      puts 'hello'
      r.session['team'] = team_code
      r.is do
        r.redirect r.full_path_info + '/'
      end
      r.root do
        {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params, session: r.session}.to_json
        view :team
      end
      r.on 'standings' do
        r.is do
          r.redirect r.full_path_info + '/'
        end
        r.root do
          "currents standings and overview"
        end
        r.on ':user_id' do |user_id|
          # @user = User.find(user_id)
          r.get do
            # @p
          end
        end
      end
      r.on 'games' do
        r.is do
          r.redirect r.full_path_info + '/'
        end
        r.root do
          @games = @team.games
          # @reservations = @user.reservations(params.verify)
          {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
          view :games
        end
        r.on ':game_number' do |game_number|
          @game = @team.game_number(game_number.to_i)
          r.is do
            r.redirect r.full_path_info + '/'
          end
          puts game_number
          # @game = @team.find_by(number: game_number)
          r.root do
            # @r
            # puts @team.inspect
            # @game.to_json
            view :game
          end
          r.get 'stats' do
            # stats from game
          end
          r.get 'results' do
            # results from game => points for picksets, rankings
          end
        end
      end

      r.on 'players' do
        r.is do
          r.redirect r.full_path_info + '/'
        end
        r.root do
          {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
        end
        r.on ':jersey' do |jersey|
          # @player = @team.find_by(jersey: jersey)
          r.root do
            # @a
          end
        end
      end
    end
  end
end

