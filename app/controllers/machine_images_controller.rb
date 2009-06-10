module MetaVirt
  module MachineImagesController
    
    get '/machine_images/new' do
      erb 'machine_images/new'.to_sym
    end
    
  end
end