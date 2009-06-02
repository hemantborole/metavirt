title = "Design Idea for simple restful web framework"

with '/:remote_base' do
  with '/instances/' do
    put '/booted' { i = Instance.find_and_update(params); i.authorized_keys }
    get '/:id'    { Instance[id] }
    delete '/:id' { i = Instance[id]; i.terminate }
    get ''        { Instance.list }
    post ''       { i = Instance.create(params); i.start }
  end
  get '' {RemoteBase.list}
  get '/:id' {RemoteBase[id]}
end

description =<<BLABLA
  Take the object returned from each route
  And attempt to convert it to what is in the accept header.
  Rescue with to_s.

  Named query params are converted to local variables. For example,
  params[:id] is also available as local variable, id.

  with "/:remote_base" {} should accept an option, :allow_nil=>true
  with "/:remote_base", :allow_nil=>true {} would allow both 
      /vmrun/instance/10
      /instance/10
  to route to the same method.  
  In the second, /instance/10, route the remote_base local variable would be nil.

  Routes are matched in the order they are defined.
  This is why 
      get '' {RemoteBase.list} 
  comes after the with 'instances' block.  Otherwise none of the instances would match.
BLABLA