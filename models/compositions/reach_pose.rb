require 'base/float'
require 'rock/models/services/pose'

module Cucumber
    module Compositions
        # Composition that verifies whether a certain pose is reached within a
        # given timeout
        class ReachPose < Syskit::Composition
            # The target pose, as a Types.base.Pose object
            argument :pose
            # The position tolerance in (x, y, z) as a Eigen::Vector3 object
            #
            # Axes that are not to be compared should be set to Base.unset
            argument :position_tolerance

            # The position tolerance in (y, p, r) as a Eigen::Vector3 object
            #
            # Rotations that are not to be compared should be set to Base.unset
            argument :orientation_tolerance

            # The timeout
            argument :timeout

            # The pose source
            add Rock::Services::Pose, as: 'pose'
            
            # The last received pose as a Types.base.samples.RigidBodyState
            # object
            attr_reader :last_pose
            
            # The pose that matched the target as a Types.base.Pose object
            attr_reader :matching_pose

            # Whether the given sample is approximately equal to the target
            # pose
            def within_tolerance?(sample)
                diff_position = (pose.position - sample.position)
                3.times do |i|
                    next if Base.unset?(position_tolerance[i])
                    return false if diff_position[i].abs > position_tolerance[i]
                end

                diff_orientation = pose.orientation.inverse() * sample.orientation;
                diff_ypr = diff_orientation.to_euler
                3.times do |i|
                    next if Base.unset?(orientation_tolerance[i])
                    return false if diff_ypr[i].abs > orientation_tolerance[i]
                end

                true
            end

            event :timed_out
            forward :timed_out => :failed

            script do
                pose_r = pose_child.pose_samples_port.reader(type: :buffer, size: 100)

                poll_until(success_event) do
                    while sample = pose_r.read_new
                        @last_pose = sample
                        if within_tolerance?(sample)
                            @matching_pose = Types.base.Pose.new(
                                position: sample.position,
                                orientation: sample.orientation)
                            success_event.emit(matching_pose)
                        end
                    end

                    if !matching_pose && timeout && (lifetime > timeout)
                        timed_out_event.emit(last_pose)
                    end
                end
            end
        end
    end
end
