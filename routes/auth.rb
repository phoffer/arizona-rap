class Rap < Sinatra::Base
  namespace '/auth/' do
    post 'login' do
      if @current_user = User.authenticate(params['name'], params['password']) #|| Admin.authenticate(params['id'], params['password'])
        if params['remember'] or request['X_MOBILE_DEVICE']
          response.set_cookie("user_id", value: @current_user._id, expires: Time.now+24*60*60, path: '/')
          # session[:user_id] = @current_user._id
        else
          session[:user_id] = @current_user._id
        end
        @current_user.admin? ? redirect('/admin/') : redirect('/')
      else
        session[:return_url] = '/'
      end
    end
    post 'signup' do
      begin
        name = params['name']
        password = params['password']
        @current_user = User.create(name: name, password: password)
        if params['remember'] or request['X_MOBILE_DEVICE']
          response.set_cookie("user_id", value: @current_user._id, expires: Time.now+24*60*60, path: '/')
          # session[:user_id] = @current_user._id
        else
          session[:user_id] = @current_user._id
        end
      rescue Exception => e
        puts e.details
      ensure
        # ensure something
      end
      redirect '/'
    end
    get 'logout' do
      session[:user_id] = nil
      response.delete_cookie('user_id', path: '/')
      redirect '/'
    end
  end
end

