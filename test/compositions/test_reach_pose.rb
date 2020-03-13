# frozen_string_literal: true

require 'cucumber/models/compositions/reach_pose'
require 'timecop'

module Cucumber
    module Compositions
        describe ReachPose do
            attr_reader :pose, :rbs, :reach_pose
            before do
                @pose = Types.base.Pose.new
                pose.position = Eigen::Vector3.new(1, 2, 3)
                pose.orientation = Eigen::Quaternion.from_angle_axis(
                    0.1, Eigen::Vector3.UnitX
                )

                @rbs = Types.base.samples.RigidBodyState.Invalid
                rbs.position = Eigen::Vector3.Zero
                rbs.orientation = Eigen::Quaternion.Identity

                @reach_pose = syskit_stub_and_deploy(
                    ReachPose.with_arguments(pose: pose, timeout: 10)
                )
            end

            def assert_times_out
                Timecop.travel(10) do
                    expect_execution.to { emit reach_pose.timed_out_event }
                end
            end

            def assert_pose_in_event_equal(rbs, actual)
                expected = {
                    x: rbs.position.x, y: rbs.position.y, z: rbs.position.z,
                    yaw: rbs.orientation.yaw, pitch: rbs.orientation.pitch,
                    roll: rbs.orientation.roll
                }
                expected.each_key do |k|
                    assert_in_delta expected[k], actual[k], 1e-6,
                                    "expected and actual values differ on #{k}: "\
                                    "#{expected[k]} and #{actual[k]}"
                end
            end

            it 'terminates successfully if the target is reached' do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)

                flexmock(reach_pose).should_receive(:within_tolerance?).and_return(true)
                sample = Types.base.samples.RigidBodyState.new
                event = expect_execution do
                    syskit_write reach_pose.pose_child.pose_samples_port, sample
                end.to { emit reach_pose.success_event }

                sample_as_pose = Types.base.Pose.new(
                    position: sample.position, orientation: sample.orientation
                )
                assert_equal [sample_as_pose], event.context
                assert_equal sample_as_pose, reach_pose.matching_pose
            end

            it 'times out if no pose samples arrive' do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                flexmock(reach_pose).should_receive(:within_tolerance?).never
                event = assert_times_out
                assert_pose_in_event_equal pose, event.context.first[:expected]
                assert_nil event.context.first[:last_pose]
            end

            it 'times out if no pose samples within tolerance arrive' do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)

                syskit_write reach_pose.pose_child.pose_samples_port, rbs
                flexmock(reach_pose).should_receive(:within_tolerance?).and_return(false)
                event = assert_times_out

                assert_pose_in_event_equal pose, event.context.first[:expected]
                assert_pose_in_event_equal rbs, event.context.first[:last_pose]
            end

            it 'does nothing if no pose samples arrive' do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                flexmock(reach_pose).should_receive(:within_tolerance?).never
                expect_execution.to do
                    not_emit reach_pose.stop_event
                end
            end

            it 'does nothing if no pose samples arrive within the tolerance' do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)

                flexmock(reach_pose).should_receive(:within_tolerance?)
                                    .once.and_return(false)
                expect_execution do
                    syskit_write reach_pose.pose_child.pose_samples_port,
                                 Types.base.samples.RigidBodyState.new
                end.to { not_emit reach_pose.stop_event }
            end

            it 'emits success if the pose and timeout are reached at the same time' do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)

                flexmock(reach_pose).should_receive(:within_tolerance?).and_return(true)
                expect_execution do
                    syskit_write reach_pose.pose_child.pose_samples_port,
                                 Types.base.samples.RigidBodyState.new
                end.to do
                    emit reach_pose.success_event
                    not_emit reach_pose.failed_event
                end
            end
        end
    end
end
