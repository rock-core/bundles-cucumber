require 'base/float'
require 'rock/models/services/pose'

module Cucumber
    module Compositions
        # Base implementation for other compositions that handle pose-related
        # predicates
        #
        # It really does nothing by itself
        class PosePredicate < Syskit::Composition
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

            # The pose source
            add Rock::Services::Pose, as: 'pose'
            
            # The last received pose as a Types.base.samples.RigidBodyState
            # object
            attr_reader :last_pose

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

            def rbs_to_hash(rbs)
                position    = Hash[[:x, :y, :z].zip(rbs.position.to_a)]
                orientation = Hash[[:yaw, :pitch, :roll].zip(rbs.orientation.to_euler.to_a)]
                position.merge(orientation)
            end

            event :timed_out
            forward :timed_out => :failed
        end
    end
end
