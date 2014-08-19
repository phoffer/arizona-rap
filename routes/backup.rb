class RodaApp < Roda

  route do |r|
    @current_user = :authorized_user
    r.get do
      # select team/season to view, or skip straight to team if previously set
      {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
    end
    r.on ':team_code' do |team_code|
      r.get do
        {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
      end
      r.on 'standings' do
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
        r.get do
          # @reservations = @user.reservations(params.verify)
          {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
        end
        r.on ':game_number' do |game_number|
          # @game = @team.find_by(number: game_number)
          r.get do
            # @r
          end
        end
      end

      r.on 'players' do
        r.get do
          {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params}.to_json
        end
        r.on ':jersey' do |jersey|
          # @player = @team.find_by(jersey: jersey)
          r.get do
            # @a
          end
        end
      end
    end
  end
end
