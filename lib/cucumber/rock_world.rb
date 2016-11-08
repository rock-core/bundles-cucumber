require 'roby/app/cucumber/world'
require 'rock_gazebo/syskit/cucumber/world'
require 'cucumber/rock_steps'

module Cucumber
    module RockWorld
        def self.setup
            require 'syskit'
            Roby.app.using 'syskit'
            Roby.app.import_types_from 'base'
        end
    end
end


