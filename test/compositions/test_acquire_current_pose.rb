require 'cucumber/models/compositions/acquire_current_pose'
require 'timecop'

module Cucumber
    module Compositions
        describe AcquireCurrentPose do
            it "times out if no samples are received within the timeout period" do
                task = syskit_stub_deploy_configure_and_start(
                    AcquireCurrentPose.with_arguments(timeout: 3))
                Timecop.freeze(Time.now + 5) do
                    plan.unmark_mission_task(task)
                    assert_event_emission task.timed_out_event
                end
            end
            it "emits success with the pose if it receives a pose sample" do
                task = syskit_stub_deploy_configure_and_start(
                    AcquireCurrentPose.with_arguments(timeout: 3))
                rbs = Types.base.samples.RigidBodyState.new
                task.pose_child.orocos_task.pose_samples.write(rbs)
                assert_event_emission task.success_event
                assert_equal [rbs], task.success_event.last.context
            end
        end
    end
end
