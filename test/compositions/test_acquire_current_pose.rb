# frozen_string_literal: true

require 'cucumber/models/compositions/acquire_current_pose'
require 'timecop'

module Cucumber
    module Compositions
        describe AcquireCurrentPose do
            it 'times out if no samples are received within the timeout period' do
                task = syskit_stub_deploy_configure_and_start(
                    AcquireCurrentPose.with_arguments(timeout: 3)
                )
                Timecop.freeze(Time.now + 5) do
                    expect_execution.to do
                        emit task.timed_out_event
                    end
                end
            end

            it 'emits success with the pose if it receives a pose sample' do
                task = syskit_stub_deploy_configure_and_start(
                    AcquireCurrentPose.with_arguments(timeout: 3)
                )
                rbs = Types.base.samples.RigidBodyState.new
                event = expect_execution do
                    syskit_write task.pose_child.pose_samples_port, rbs
                end.to { emit task.success_event }
                assert_equal [rbs], event.context
            end
        end
    end
end
