require 'bundler/capistrano'
require 'rvm/capistrano'

set :rvm_ruby_string, '2.0.0'
set :rvm_type, :system

set :application, "poirot"
set :repository,  "https://github.com/instedd/poirot.git"
set :scm, :git

# role :web, "your web-server here"                          # Your HTTP server, Apache/etc
# role :app, "your app-server here"                          # This may be the same as your `Web` server
# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

after "deploy:restart", "deploy:cleanup"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
