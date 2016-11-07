require 'models/compositions/warp_robot'

module Cucumber
    module Actions
        # Actions required for the Cucumber/Syskit integration
        class Cucumber < Roby::Actions::Interface
            describe('cucumber_warp_robot').
                required_arg(:pose, 'the pose the robot should be placed at').
                returns(Compositions::WarpRobot)
            def cucumber_warp_robot(arguments)
                Compositions::WarpRobot.
                    with_arguments(pose: arguments[:pose])
            end
        end
    end
end

