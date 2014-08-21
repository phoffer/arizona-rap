class Rap < Sinatra::Base
  namespace '/auth/' do
    post 'login' do
      if @current_user = User.authenticate(params['id'], params['password']) #|| Admin.authenticate(params['id'], params['password'])
        if params['remember'] or request['X_MOBILE_DEVICE']
          response.set_cookie("user_id", value: @current_user._id, expires: Time.now+24*60*60, path: '/')
          # session[:user_id] = @current_user._id
        else
          session[:user_id] = @current_user._id
        end
      else
        # session[:return_url] = '/'
      end
      # puts session[:_id]
      redirect '/'
      # do something here if @_request.xhr?
    end
    post 'signup' do
      begin
        name = params['name']
        password = params['password']
        @current_user = User.create(name: name, password: password)
        response.set_cookie('user_id', value: @current_user._id, expires: Time.now+24*60*60, path: '/')
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

