require 'cucumber/models/compositions/warp_robot'
require 'cucumber/models/compositions/reach_pose'
require 'cucumber/models/compositions/maintain_pose'
require 'cucumber/models/compositions/acquire_current_pose'
require 'cucumber/models/tasks/job_emits_event'
require 'cucumber/models/tasks/settle'

module Cucumber
    module Actions
        # Actions required for the Cucumber/Syskit integration
        #
        # Subclass it into your bundle and inject the robot-under-test into
        # the return value of the pose-related actions:
        #
        #     class Cucumber << Cucumber::Actions::Cucumber
        #       def cucumber_warp_robot(**)
        #           super.use(Base.motoman_dev)
        #       end
        #
        #       def cucumber_maintain_pose(**)
        #           super.use(Base.motoman_dev)
        #       end
        #
        #       def cucumber_reach_pose(**)
        #           super.use(Base.motoman_dev)
        #       end
        #
        #       def cucumber_acquire_current_pose(**)
        #           super.use(Base.motoman_dev)
        #       end
        #     end
        #
        class Cucumber < Roby::Actions::Interface
            describe('cucumber_warp_robot').
                required_arg(:pose, 'the pose the robot should be placed at').
                returns(Compositions::WarpRobot)
            def cucumber_warp_robot(arguments)
                Compositions::WarpRobot.with_arguments(arguments)
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

            describe('acquires the current pose and embeds it into its success event as a Types.base.Pose object').
                optional_arg(:timeout, 'how long the pose acquisition is allowed to take', 1).
                returns(Compositions::AcquireCurrentPose)
            def cucumber_acquire_current_pose(timeout: 1)
                Compositions::AcquireCurrentPose.with_arguments(timeout: timeout)
            end

            describe('verifies that the vehicle stays at its current pose during a certain timeframe').
                required_arg(:position_tolerance, 'the position tolerance, as a Eigen::Vector3. Use Base.unset to ignore an axis.').
                required_arg(:orientation_tolerance, 'the orientation tolerance, as a Eigen::Vector3 (RPY). Use Base.unset to ignore an axis.').
                required_arg(:acquisition_timeout, 'how long the pose acquisition is allowed to take').
                required_arg(:duration, 'how long the pose should be maintained in seconds')
            action_state_machine 'cucumber_stays_still' do
                acquire = state(cucumber_acquire_current_pose(timeout: acquisition_timeout))
                start(acquire)
                current_pose = capture(acquire.success_event) do |event|
                    rbs = event.context.first
                    Types.base.Pose.new(
                        position: rbs.position,
                        orientation: rbs.orientation)
                end

                maintain_pose = state(cucumber_maintain_pose(
                    pose: current_pose, position_tolerance: position_tolerance, orientation_tolerance: orientation_tolerance, duration: duration))
                transition acquire.success_event, maintain_pose
                forward maintain_pose.success_event, success_event
            end

            describe('verifies that an event is emitted within a certain timeframe').
                required_arg(:timeout, 'the time in seconds after which the task fails if the event is still not emitted').
                required_arg(:event_name, 'the name of the event').
                required_arg(:monitored_job_id, 'the job ID of the task being watched').
                returns(Tasks::JobEmitsEvent)
            def cucumber_job_emits_event(arguments)
                Tasks::JobEmitsEvent.new(arguments)
            end

            describe('runs until the controller is settled').
                returns(Tasks::Settle)
            def cucumber_settle
                Tasks::Settle.new
            end
        end
    end
end

