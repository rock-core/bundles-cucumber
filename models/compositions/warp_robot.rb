require 'common_models/models/devices/gazebo/root_model'
require 'cucumber/models/compositions/pose_predicate'

module Cucumber
    module Compositions
        # A composition that encapsulates moving the robot to a desired place in
        # a Gazebo environment
        #
        # It never finished
        class WarpRobot < Syskit::Composition
            argument :pose

            # The model that will be warped
            #
            # When overloading the cucumber_warp_robot action, it is
            # automatically used for the pose_child as well
            add CommonModels::Devices::Gazebo::RootModel, as: 'model'

            # The target pose a Types.base.samples.RigidBodyState, ready to be
            # sent to model_child
            attr_reader :rbs_pose

            def initialize(arguments = Hash.new)
                @rbs_pose = Types.base.samples.RigidBodyState.Invalid
                super
            end

            def pose=(pose)
                arguments[:pose] = pose
                rbs_pose.position    = pose.position
                rbs_pose.orientation = pose.orientation
            end

            script do
                pose_w = model_child.model_pose_port.writer

                wait_until_ready pose_w
                poll do
                    rbs_pose.time = Time.now
                    pose_w.write(rbs_pose)
                end
            end
        end
    end
end
