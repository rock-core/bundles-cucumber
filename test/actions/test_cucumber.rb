require 'models/actions/cucumber'

module Cucumber
    module Actions
        describe Cucumber do
            attr_reader :stub_interface_m
            before do
                stub_model_m  = syskit_stub_requirements(OroGen::RockGazebo::ModelTask)
                @stub_interface_m = Cucumber.new_submodel do
                    define_method(:stub_model_m) { stub_model_m }

                    def cucumber_warp_robot(arguments)
                        super.use('model' => stub_model_m)
                    end

                    def cucumber_reach_pose(arguments)
                        super.use('pose' => stub_model_m)
                    end

                    def cucumber_maintain_pose(arguments)
                        super.use('pose' => stub_model_m)
                    end
                end
            end

            describe "cucumber_warp_robot" do
                it "creates a WarpRobot composition with the expected pose" do
                    pose = Types.base.Pose.new
                    pose.position = Eigen::Vector3.Zero
                    pose.orientation = Eigen::Quaternion.Identity

                    task = plan.add_permanent_task(stub_interface_m.cucumber_warp_robot.with_arguments(pose: pose))
                    task = roby_run_planner(task)
                    assert_kind_of Compositions::WarpRobot, task
                    assert_equal pose, task.pose
                end
            end

            describe "cucumber_reach_pose" do
                it "creates a ReachPose composition with the expected pose, tolerances and timeout" do
                    pose = Types.base.Pose.new
                    pose.position = Eigen::Vector3.Zero
                    pose.orientation = Eigen::Quaternion.Identity

                    task = plan.add_permanent_task(
                        stub_interface_m.cucumber_reach_pose.with_arguments(
                            pose: pose,
                            position_tolerance: (tol_p = Eigen::Vector3.new),
                            orientation_tolerance: (tol_q = Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitZ)),
                            timeout: 20))
                    task = roby_run_planner(task)
                    assert_kind_of Compositions::ReachPose, task
                    assert_equal pose, task.pose
                    assert_equal tol_p, task.position_tolerance
                    assert_equal tol_q, task.orientation_tolerance
                    assert_equal 20, task.timeout
                end
            end

            describe "cucumber_maintain_pose" do
                it "creates a MaintainPose composition with the expected pose, tolerances and duration" do
                    pose = Types.base.Pose.new
                    pose.position = Eigen::Vector3.Zero
                    pose.orientation = Eigen::Quaternion.Identity

                    task = plan.add_permanent_task(
                        stub_interface_m.cucumber_maintain_pose.with_arguments(
                            pose: pose,
                            position_tolerance: (tol_p = Eigen::Vector3.new),
                            orientation_tolerance: (tol_q = Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitZ)),
                            duration: 20))
                    task = roby_run_planner(task)
                    assert_kind_of Compositions::MaintainPose, task
                    assert_equal pose, task.pose
                    assert_equal tol_p, task.position_tolerance
                    assert_equal tol_q, task.orientation_tolerance
                    assert_equal 20, task.duration
                end
            end
        end
    end
end
