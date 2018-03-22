require 'cucumber/models/compositions/maintain_pose'
require 'timecop'

module Cucumber
    module Compositions
        describe MaintainPose do
            attr_reader :pose, :rbs, :maintain_pose
            before do
                @pose = Types.base.Pose.new
                pose.position = Eigen::Vector3.new(1, 2, 3)
                pose.orientation = Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitX)

                @rbs = Types.base.samples.RigidBodyState.Invalid
                rbs.position = Eigen::Vector3.Zero
                rbs.orientation = Eigen::Quaternion.Identity

                @maintain_pose = syskit_stub_and_deploy(
                    MaintainPose.with_arguments(pose: pose, duration: 10))
            end

            def assert_pose_in_event_equal(rbs, actual)
                expected = Hash[x: rbs.position.x, y: rbs.position.y, z: rbs.position.z,
                                yaw: rbs.orientation.yaw, pitch: rbs.orientation.pitch, roll: rbs.orientation.roll]
                expected.each_key do |k|
                    assert_in_delta expected[k], actual[k], 1e-6, "expected and actual values differ on #{k}: #{expected[k]} and #{actual[k]}"
                end
            end


            it "terminates successfully if the target pose is maintained within the expected duration" do
                maintain_pose.position_tolerance = Eigen::Vector3.new
                maintain_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(maintain_pose)
                flexmock(maintain_pose).should_receive(:within_tolerance?).and_return(true)
                sample = nil
                Timecop.freeze do
                    10.times do
                        Timecop.travel(1)
                        maintain_pose.pose_child.orocos_task.pose_samples.
                            write(sample = Types.base.samples.RigidBodyState.new)
                        process_events
                    end
                end
                assert maintain_pose.success_event.emitted?
            end

            it "fails at the end of the period if no samples were ever received" do
                maintain_pose.position_tolerance = Eigen::Vector3.new
                maintain_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(maintain_pose)
                plan.unmark_mission_task(maintain_pose)
                Timecop.travel(10) do
                    assert_event_emission(maintain_pose.no_samples_event, garbage_collect_pass: false)
                end
            end

            it "ignores the duration if none is provided" do
                maintain_pose = syskit_stub_and_deploy(
                    MaintainPose.with_arguments(pose: pose, duration: nil))
                maintain_pose.position_tolerance = Eigen::Vector3.new
                maintain_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(maintain_pose)
                Timecop.travel(10) do
                    process_events
                    assert maintain_pose.running?
                end
            end

            it "fails if a sample outside tolerance is received" do
                maintain_pose.position_tolerance = Eigen::Vector3.new
                maintain_pose.orientation_tolerance = Eigen::Vector3.new
                syskit_configure_and_start(maintain_pose)
                maintain_pose.pose_child.orocos_task.pose_samples.write(rbs)
                flexmock(maintain_pose).should_receive(:within_tolerance?).and_return(false)
                plan.unmark_mission_task(maintain_pose)

                event = assert_event_emission(maintain_pose.exceeds_tolerance_event, garbage_collect_pass: false)
                assert_pose_in_event_equal pose, event.context.first[:expected]
                assert_pose_in_event_equal rbs, event.context.first[:actual]
            end
        end
    end
end
