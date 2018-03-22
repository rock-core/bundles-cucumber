require 'cucumber/models/compositions/warp_robot'

module Cucumber
    module Compositions
        describe WarpRobot do
            attr_reader :pose, :warp_task, :in_port, :out_port
            before do
                @pose = Types.base.Pose.new
                pose.position = Eigen::Vector3.new(1, 2, 3)
                pose.orientation = Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitX)
                @warp_task = syskit_stub_deploy_and_configure(
                    WarpRobot.with_arguments(pose: pose))
                syskit_start_execution_agents(warp_task.model_child)
                @in_port  = warp_task.model_child.orocos_task.model_pose
                @out_port = warp_task.model_child.orocos_task.pose_samples
            end

            it "initializes #rbs_pose with its #pose argument at initialization" do
                warp = WarpRobot.new(pose: pose)
                assert_equal warp.pose.position, warp.rbs_pose.position
                assert_equal warp.pose.orientation, warp.rbs_pose.orientation
            end

            it "allows a late setting of the pose argument" do
                warp = WarpRobot.new
                warp.pose = pose
                assert_equal warp.pose.position, warp.rbs_pose.position
                assert_equal warp.pose.orientation, warp.rbs_pose.orientation
            end

            it "writes the pose to its designated model" do
                syskit_start(@warp_task)
                pose = assert_has_one_new_sample(in_port)
                assert_equal pose.position, pose.position
                assert_equal pose.orientation, pose.orientation
            end
        end
    end
end
