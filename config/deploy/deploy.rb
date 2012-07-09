Capistrano::Configuration.instance(:must_exist).load do

  namespace :deploy do

    desc "Deploy codebase onto an empty server"
    task :install do 
      permissions.remote

      deploy.setup
      deploy.update

      #gems.install

      #if servers? :worker
      #  workers.start
      #end

      #logrotate.install

      #if servers? :worker
      #  monit.config_worker
      #end

      #monit.restart
    end
     
    desc "Deploy delta codebase update onto a pre-deployed server"
    task :release do 

      deploy.update

      #gems.install

      #if servers? :worker
      #  workers.restart
      #end

      #if servers? :worker
      #  monit.config_worker
      #end

      #monit.restart
    end

  end

end
