module MetaVirt
  class MachineImagesController < Sinatra::Base
    configure do
      set :views, File.dirname(__FILE__) + '/../views/machine_images/'
    end
    
    get '/' do
      erb :index
    end
    
    get '/new' do
      erb :new
    end
    
  end
end