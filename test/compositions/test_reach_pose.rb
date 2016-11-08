require 'models/compositions/reach_pose'
require 'timecop'

module Cucumber
    module Compositions
        describe ReachPose do
            attr_reader :pose, :rbs, :reach_pose
            before do
                @pose = Types.base.Pose.new
                pose.position = Eigen::Vector3.new(1, 2, 3)
                pose.orientation = Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitX)

                @rbs = Types.base.samples.RigidBodyState.Invalid
                rbs.position = Eigen::Vector3.Zero
                rbs.orientation = Eigen::Quaternion.Identity

                @reach_pose = syskit_stub_and_deploy(
                    ReachPose.with_arguments(pose: pose, timeout: 10))
            end

            def assert_times_out
                plan.unmark_mission_task reach_pose
                Timecop.travel(10) do
                    assert_event_emission(reach_pose.timed_out_event, garbage_collect_pass: false)
                end
            end

            it "terminates successfully if the target is reached" do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                reach_pose.pose_child.orocos_task.pose_samples.
                    write(sample = Types.base.samples.RigidBodyState.new)
                flexmock(reach_pose).should_receive(:within_tolerance?).and_return(true)
                event = assert_event_emission reach_pose.success_event

                sample_as_pose = Types.base.Pose.new(position: sample.position, orientation: sample.orientation)
                assert_equal [sample_as_pose], event.context
                assert_equal sample_as_pose, reach_pose.matching_pose
            end

            it "times out if no pose samples arrive" do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                flexmock(reach_pose).should_receive(:within_tolerance?).never
                event = assert_times_out
                assert_equal [nil], event.context
            end

            it "times out if no pose samples within tolerance arrive" do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                reach_pose.pose_child.orocos_task.pose_samples.write(rbs)
                flexmock(reach_pose).should_receive(:within_tolerance?).and_return(false)
                event = assert_times_out
                assert_equal [rbs], event.context
            end

            it "does nothing if no pose samples arrive" do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                flexmock(reach_pose).should_receive(:within_tolerance?).never
                process_events
                assert reach_pose.running?
            end

            it "does nothing if no pose samples arrive within the tolerance" do
                reach_pose.position_tolerance = Eigen::Vector3.new
                reach_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(reach_pose)
                reach_pose.pose_child.orocos_task.pose_samples.
                    write(Types.base.samples.RigidBodyState.new)
                flexmock(reach_pose).should_receive(:within_tolerance?).once.and_return(false)
                process_events
                assert reach_pose.running?
            end
        end
    end
end
