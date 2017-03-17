require 'rock/models/services/pose'

module Cucumber
    module Compositions
        # Acquire a sample from a pose provider and emits it with the success
        # event
        class AcquireCurrentPose < Syskit::Composition
            argument :timeout

            add Rock::Services::Pose, as: 'pose'

            event :timed_out
            forward :timed_out => :failed

            script do
                pose_reader = pose_child.pose_samples_port.reader
                poll do
                    if pose = pose_reader.read
                        success_event.emit(pose)
                    elsif lifetime > timeout
                        timed_out_event.emit
                    end
                end
            end
        end
    end
end
