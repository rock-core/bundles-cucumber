require 'cucumber/models/compositions/pose_predicate'

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
                pose_r = pose_child.pose_samples_port.reader(type: :buffer, size: 10)

                poll_until(success_event) do
                    if sample = pose_r.read_new
                        @last_pose = sample
                    end

                    if sample && within_tolerance?(sample)
                        @matching_pose = Types.base.Pose.new(
                            position: sample.position,
                            orientation: sample.orientation)
                        success_event.emit(matching_pose)
                    elsif timeout && (lifetime > timeout)
                        timed_out_event.emit(
                            Hash[expected: rbs_to_hash(self.pose),
                                 last_pose: (rbs_to_hash(last_pose) if last_pose)])
                    end
                end
            end
        end
    end
end
