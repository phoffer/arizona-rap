class RodaApp < Roda

  route 'admin' do |r|
    puts 'admin area'
    r.is do
      'admin area'
    end
    r.root do

      # view :index
      {verb: r.env['REQUEST_METHOD'], path: r.full_path_info, params: r.params, note: 'admin area'}.to_json
    end
    r.on 'admin' do
      r.get do
        "hello"
      end
      r.post do
        # login
        # error handle for bad login
      end
      r.delete do
        # logout
        r.halt(401, {error: 'No session exists.'}.to_json)
        # return...nothing?
      end
    end
  end
end
