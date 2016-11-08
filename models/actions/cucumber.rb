require 'models/compositions/warp_robot'
require 'models/compositions/reach_pose'
require 'models/compositions/maintain_pose'

module Cucumber
    module Actions
        # Actions required for the Cucumber/Syskit integration
        class Cucumber < Roby::Actions::Interface
            describe('cucumber_warp_robot').
                required_arg(:pose, 'the pose the robot should be placed at').
                returns(Compositions::WarpRobot)
            def cucumber_warp_robot(arguments)
                Compositions::WarpRobot.with_arguments(arguments).
                    use('pose' => Compositions::WarpRobot.model_child)
            end

            describe('verifies that the vehicle maintains a pose with tolerance for a specified amount of time').
                required_arg(:pose, 'the expected pose, as a base/Pose').
                required_arg(:position_tolerance, 'the position tolerance, as a Eigen::Vector3. Use Base.unset to ignore an axis.').
                required_arg(:orientation_tolerance, 'the orientation tolerance, as a Eigen::Vector3 (RPY). Use Base.unset to ignore an axis.').
                required_arg(:timeout, 'the duration, in seconds, into which the pose should reach the expected').
                returns(Compositions::ReachPose)
            def cucumber_reach_pose(arguments)
                Compositions::ReachPose.with_arguments(arguments)
            end

            describe('verifies that the vehicle maintains a pose with tolerance for a specified amount of time').
                required_arg(:pose, 'the expected pose, as a base/Pose').
                required_arg(:position_tolerance, 'the position tolerance, as a Eigen::Vector3. Use Base.unset to ignore an axis.').
                required_arg(:orientation_tolerance, 'the orientation tolerance, as a Eigen::Vector3 (RPY). Use Base.unset to ignore an axis.').
                required_arg(:duration, 'how long the pose should be maintained in seconds').
                returns(Compositions::MaintainPose)
            def cucumber_maintain_pose(arguments)
                Compositions::MaintainPose.with_arguments(arguments)
            end
        end
    end
end

