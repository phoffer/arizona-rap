require 'roda'
class RodaApp < Roda
  route 'main' do |r|
    @current_user = :authorized_user
    r.root do
      # select team/season to view, or skip straight to team if previously set
      {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params, note: 'main'}.to_json
    end
    puts r.full_path_info
    r.on ':team_code' do |team_code|
      r.is do
        r.redirect r.full_path_info + '/'
      end
      r.root do
        {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
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
          # @reservations = @user.reservations(params.verify)
          {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
        end
        r.on ':game_number' do |game_number|
          # @game = @team.find_by(number: game_number)
          r.root do
            # @r
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

