require 'config/deploy/staging'
require 'config/deploy/production'
require 'config/deploy/helpers'
require 'config/deploy/deploy'
require 'config/deploy/permissions'


set :application, "crawler"

set :scm, :git
set :repository,  "git@github.com:Denwen/Mine-Crawler.git"
set :user,          "manager"  
set :deploy_via,    :remote_cache
set :keep_releases, 10
set :git_enable_submodules, 1

set :deploy_to,     "/vol/#{application}"
set :use_sudo,      false

default_run_options[:pty]   = true
ssh_options[:forward_agent] = true
ssh_options[:paranoid] = false
















