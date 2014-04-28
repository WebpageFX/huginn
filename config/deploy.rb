# This is an example Capistrano deployment script for Huginn.  It
# assumes you're running on an Ubuntu box and want to use Foreman,
# Upstart, and Unicorn.
default_run_options[:pty] = true

set :application, "huginn"
set :bundle_flags, '--deployment --quiet --binstubs'
set :deploy_to, ENV['DEPLOY_PATH']
set :log_level, :debug
set :user, ENV['DEPLOY_USER']
set :use_sudo, false
set :scm, :git
set :rails_env, 'production'
set :repository, "git@github.com:WebpageFX/huginn.git"
set :branch, ENV['BRANCH'] || "master"
set :deploy_via, :remote_cache
set :keep_releases, 5
set :default_environment, {
    'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

puts "    Deploying #{branch}"

set :bundle_without, [:development]

server ENV['DOMAIN'], :app, :web, :db, :primary => true

set :sync_backups, 3

before 'deploy:restart', 'deploy:migrate'
after 'deploy', 'deploy:cleanup'

set :bundle_without, [:development, :test]

after 'deploy:update_code', 'deploy:symlink_configs'
after 'deploy:update', 'foreman:export'
after 'deploy:update', 'foreman:restart'

namespace :deploy do
  desc 'Link the config files in the new current directory'
  task :symlink_configs, :roles => :app do
    run <<-CMD
      cd #{latest_release} && ln -nfs #{shared_path}/config/.env #{latest_release}/.env
    CMD

    run <<-CMD
      cd #{latest_release} && ln -nfs #{shared_path}/config/Procfile #{latest_release}/Procfile
    CMD

    run <<-CMD
      cd #{latest_release} && ln -nfs #{shared_path}/config/database.yml #{latest_release}/config/
    CMD
  end
end

namespace :foreman do
  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => :app do
    run "cd #{latest_release} && rbenv sudo bundle exec foreman export upstart /etc/init -a #{application} -u #{user} -l #{deploy_to}/upstart_logs"
  end

  desc 'Start the application services'
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc 'Stop the application services'
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc 'Restart the application services'
  task :restart, :roles => :app do
    sudo "restart #{application}"
  end
end

# Load Capistrano additions
Dir[File.expand_path("../../lib/capistrano/*.rb", __FILE__)].each{|f| load f }

require "bundler/capistrano"
load 'deploy/assets'
