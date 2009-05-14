class Object
  def route_stack
    @route_stack ||= []
  end
  def with(route, &block)
    route_stack.push route
    instance_eval &block
    route_stack.pop
  end
  def routes
    @routes ||= {}
  end
  def route(meth, route, &block)
    (routes[meth] ||= []) << [resolve_route(route), block]
  end
  def resolve_route(r)
    route_stack.join("/") + (r.empty? ? "" : "/#{r}")
  end
  %w(get post put delete).each do |meth|
    class_eval <<-EOE  
      def #{meth}(route, &block)
        route(:#{meth}, route, &block)
      end
    EOE
  end
end
 
with '/:remote_base' do
  with 'instances' do
    put 'booted' do; end
    get ':id'    do; end
    delete ':id' do; end
    get ''        do; end
    post ''       do; end
  end
  get '' do; end
  get ':id' do; end  
end
 
get '' do; end

require 'rubygems'
require 'facets'
require 'facets/xoxo'

# routes.each{|r|  (r.respond_to?(:call) ? r.call : r)}
# def print_routes(r, accumulator=[])
#   accumulator << (r.respond_to?(:call) ? r.call : r)
# end
# 
# 
# File.open('routes.html', 'w'){|f| f<<XOXO.dump(routes)
#   f.write "<pre>#{routes.inspect}</pre>"
#   }
# `open routes.html`
p routes

p resolve_route '//instances'