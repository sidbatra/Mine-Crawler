Capistrano::Configuration.instance(:must_exist).load do

  desc "Setup configuration variables for deploying in a "\
        "production environment"
  task :production do

    # Population of roles requires setting up of environment
    # variables for the different roles. The expected syntax
    # is a simple csv.
    #
    role(:crawler)          { "ec2-23-23-124-178.compute-1.amazonaws.com" }
    
    set :environment, "production"
    set :branch, "master"
  end

end
