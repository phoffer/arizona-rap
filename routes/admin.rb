class RodaApp < Roda

  route 'admin' do |r|
    @current_user = Admin.find(@user_id)   # => change to Admin.find(id)
    @base_url = '/admin/'
    r.root do
      @teams = Team.all
      # list teams and create a new team
      # view :index
      @content = {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params, note: 'admin area'}
      view :'admin/main'
    end
    r.redirect '/admin/' unless @current_user
    r.post 'teams' do
      # create team here
      if t = Team.find_by(year: r.params['year'], sport: r.params['sport'])
        t.update(r.params)
      else
        t = Team.create(r.params)
      end

      r.redirect "/admin/#{t.code}"
    end
    r.on ':team_code' do |team_code|
      @team = Team.find_by(code: team_code)
      @base_url << "#{@team.code}/"
      r.is do
        r.redirect r.full_path_info + '/'
      end
      r.root do
        "hello"
        view :'admin/team'
      end
      r.post do
        # login
        # error handle for bad login
      end
      r.get 'open' do
        @team.open
        r.redirect r.referrer
      end
      r.get 'close' do
        @team.close
        r.redirect r.referrer
      end
      r.get 'finalize' do
        @team.finalize
        r.redirect r.referrer
      end
      r.get 'delete' do
        @team.delete
        r.redirect '/admin/'
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
          @game = @team.game_number(game_number)
          @base_url << "games/#{@game.number}/"
          r.is do
            r.redirect r.full_path_info + '/'
          end
          # @game = @team.find_by(number: game_number)
          r.root do
            # @r
            game_number.to_s
            view :'admin/game'
          end
          r.get 'stats' do
            # file upload or maybe big form
            # google spreadsheet?

            # stats from game
          end
          r.get 'results' do
            # results from game => points for picksets, rankings
          end
          r.on 'status' do
            puts r.full_path_info
            r.get 'prepare' do
              @game.prepare
              r.redirect r.referrer
            end
            r.get 'price' do
              arr = r.params['ids'].zip(r.params['dol']).reject{ |_, d| d.empty? }
              # puts arr.map(&:inspect)
              @game.price(arr)
              r.redirect r.referrer
            end
            puts r.full_path_info
            r.post 'price' do
              puts 'posted'
              # validate r.params['prices'] is a proper array
              # @prices = r.params['ids'].zip(r.params['dol'])
              # puts @prices.inspect
              # @prices.reject!{ |_, p| p.empty? }
              # puts @prices.inspect


              # @game.price(r.params['prices'])
              r.redirect r.referrer
            end
            r.get 'confirm' do
              @game.update_time(r.params['time'])
              r.redirect r.referrer
            end
            r.get 'open' do
              @game.open
              # notify people? make post on forum?
              r.redirect r.referrer
            end
            r.get 'lock' do
              # ensure that Time.now > @game.time
              @game.lock
              r.redirect r.referrer
            end
            r.get 'stats' do
              # stats = ra.params['file_upload'] or google spreadsheet
              path = 'stats.csv'
              stats = ScoringGuide.import_stats_csv(path)
              @game.score(stats) # ok i guess we'll score it too. if it's a file upload
              r.redirect r.referrer
            end
            r.get 'score' do
              # this will be separate if the stats are done by google sheet
              # otherwise these two can't be separated
              # @game.score(spreadsheet_data)
              r.redirect r.referrer
            end
            r.get 'finalize' do
              @game.update_standings
              r.redirect r.referrer
            end
            r.get 'next' do
              r.redirect r.referrer.gsub("games/#{@game.number}", "games/#{@game.number + 1}")
            end
          end
        end
      end
    end
  end
end
