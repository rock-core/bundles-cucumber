using_task_library 'rock_gazebo'

module Cucumber
    module Compositions
        # A composition that encapsulates moving the robot to a desired place in
        # a Gazebo environment
        class WarpRobot < Syskit::Composition
            argument :pose

            # The model that will be warped
            add OroGen::RockGazebo::ModelTask, as: 'model'

            # Whether the given sample is approximately equal to the target
            # pose
            def approx?(pose, sample)
                pose.position.approx?(sample.position) &&
                    pose.orientation.approx?(sample.orientation)
            end

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
                pose_r = model_child.pose_samples_port.reader(type: :buffer, size: 100)
                pose_w = model_child.model_pose_port.writer

                wait_until_ready pose_w
                poll_until(success_event) do
                    rbs_pose.time = Time.now
                    pose_w.write(rbs_pose)
                    while sample = pose_r.read_new
                        if approx?(pose, sample)
                            success_event.emit
                        end
                    end
                end
            end
        end
    end
end
