require 'models/compositions/pose_predicate'

module Cucumber
    module Compositions
        # Composition that verifies whether a certain pose is reached within a
        # given timeout
        class ReachPose < PosePredicate
            # The timeout
            argument :timeout

            # The pose that matched the target as a Types.base.Pose object
            attr_reader :matching_pose

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
