require 'sinatra/base'
require "sinatra/reloader"
require 'sinatra/contrib/all'

require 'haml'
require 'sass'
require 'kramdown'
require 'coffee-script'
require 'awesome_print'
require 'pathname'
require 'multi_json'

# require own files
Dir["lib/**/*.rb"].each {|f| require "./#{f}"}

class App < Sinatra::Base
  
  register Sinatra::Contrib
  #
  # Configuration
  #
  configure do
    set :root, __dir__
    
    set :server, :thin
    set :sessions, true
    set :lock, true
    
    set default_encoding: 'UTF-8'
    set :haml, { format: :html5 } 
    set :claim_dir, Proc.new { File.join(settings.root,'claims') }
    
  end
  
  configure :development do
    register Sinatra::Reloader
    Dir["lib/**/*.rb"].each {|f| also_reload "./#{f}" }
    set :logging, true
  end

  configure :production do
    set :haml, { ugly: true }
  end
  
  #
  # Helpers
  #
  # contribute helpers
  helpers Sinatra::Cookies
  # own helpers
  helpers Sinatra::Partials
  helpers Sinatra::LinkTo
  helpers Sinatra::UrlHandle
  
  helpers do
    include Rack::Utils
    alias_method :h, :escape_html
    
    def is_to_old_browser?
      if request.user_agent.include?("MSIE") && !request.user_agent.include?("MSIE 10.0")
        return true
      else
        return false
      end
    end
    
    def img name
      "<img src='images/#{name}' alt='#{name}' />"
    end
    
  end
  
  # 
  # Filters
  # 
  before do
    @documents = Documents.content_of(dir: File.join(settings.claim_dir), root: File.join(settings.root)).flatten
  end
  
  #
  # Routes
  #
  get '/landing' do
    haml :landing, :layout => :layout_landing
  end
  
  not_found do
    redirect '/404.html'
  end

  get '/javascripts/:name.js' do
    content_type 'text/plain', :charset => 'utf-8'
    coffee :"../assets/javascripts/#{params[:name]}"
  end
  
  get '/stylesheets/:name.css' do
    content_type 'text/css', :charset => 'utf-8'
    scss :"../assets/stylesheets/#{params[:name]}"
  end

  get "/" do
    haml :index
  end
  
  get %r{/?((?<path>[\w\-\_]*)/)(?<name>[\w\-\_]+).json} do
    if params[:path].empty?
      doc_path = params[:name]  + '.json'
    else params[:path] != '/'
      doc_path = params[:path] + '/' + params[:name]  + '.json'
    end
    
    doc_path = File.join(File.join(settings.claim_dir,doc_path))
    
    @document = Documents.new path: doc_path, name: params[:name]
    
    
    if request.xhr?
      json @document.out
    else
      redirect '/'
    end
  end
  
  
  run! if app_file == $0
end
