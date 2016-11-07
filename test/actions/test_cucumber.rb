require 'models/actions/cucumber'

module Cucumber
    module Actions
        describe Cucumber do
            describe "cucumber_warp_robot" do
                it "creates a WarpRobot composition with the expected pose" do
                    pose = Types.base.Pose.new
                    pose.position = Eigen::Vector3.Zero
                    pose.orientation = Eigen::Quaternion.Identity

                    task = plan.add_permanent_task(warp_robot.with_arguments(pose: pose))
                    task = roby_run_planner(task)
                    assert_kind_of Compositions::WarpRobot, task
                    assert_equal pose, task.pose
                end
            end
        end
    end
end
