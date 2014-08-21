class RodaApp < Roda

  route 'auth' do |r|
    set_view_subdir "admin"
    r.post 'login' do
      # log the user in
      # puts r.params['id']
      # puts r.params['password']
      if @current_user = User.authenticate(r.params['id'], r.params['password']) #|| Admin.authenticate(r.params['id'], r.params['password'])
        # puts 'auth success'
        if r.params['remember'] or r.env['X_MOBILE_DEVICE']
          response.set_cookie("user_id", value: @current_user._id, expires: Time.now+24*60*60, path: '/')
          # r.session['user_id'] = @current_user._id
        else
          r.session['user_id'] = @current_user._id
        end
      else
        r.session['return_url'] = '/'
      end
      # puts r.session['_id']
      r.redirect r.referrer
      # do something here if @_request.xhr?
    end
    r.post 'signup' do
      begin
        name = r.params['name']
        password = r.params['password']
        @current_user = User.create(name: name, password: password)
        response.set_cookie('user_id', value: @current_user._id, expires: Time.now+24*60*60, path: '/')
      rescue Exception => e
        puts e.details
      ensure
        # ensure something
      end
      r.redirect '/'
    end
    r.get 'logout' do
      r.session['user_id'] = nil
      response.delete_cookie('user_id', path: '/')
      r.redirect '/'
    end
  end
end

