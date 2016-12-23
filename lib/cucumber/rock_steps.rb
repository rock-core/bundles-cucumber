require 'cucumber/rock_helpers'

Given(/^the (\w+) robot starting at (.*) in (?:the )?(.*)$/) do |robot_name, start_position, world|
    if start_position == 'origin'
        start_position = Hash[x: 0, y: 0, z: 0, yaw: 0]
    else
        start_position = Roby::App::CucumberHelpers.parse_arguments(start_position)
    end
    world = world.gsub(/\s/, '_')
    roby_controller.roby_start robot_name, robot_name,
        state: Hash['gazebo.world_file_path' => world]
    gazebo_start world, working_directory: roby_controller.roby_log_dir

    x, y, z, yaw = start_position.values_at(:x, :y, :z, :yaw)
    pose = Types.base.Pose.new(
        position: Eigen::Vector3.new(x || 0, y || 0, z || 0),
        orientation: Eigen::Quaternion.from_angle_axis(yaw || 0, Eigen::Vector3.UnitZ))
    roby_controller.run_job 'cucumber_warp_robot',
        pose: pose

end
When(/^it runs the (.*) (action|definition) with (.*)$/) do |action_name, action_kind, raw_arguments|
    action_name = Cucumber::RockHelpers.massage_action_name(action_name, action_kind)
    arguments   = Roby::App::CucumberHelpers.parse_arguments(raw_arguments)
    roby_controller.start_job "When it runs #{action_name} with #{raw_arguments}",
        action_name, **arguments
end
Then(/^the pose reaches (.*) with a tolerance of (.*) within (.*)$/) do |pose, tolerance, timeout|
    pose, position_tolerance, orientation_tolerance = Cucumber::RockHelpers.parse_pose_and_tolerance(pose, tolerance)
    timeout, _ = Roby::App::CucumberHelpers.parse_numerical_value(timeout)
    roby_controller.run_job 'cucumber_reach_pose',
        pose: pose, position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance, timeout: timeout
end
Then(/^it is (.*) within (.*)$/) do |event_name, timeout|
    timeout, _ = Roby::App::CucumberHelpers.parse_numerical_value(timeout)
    roby_controller.run_job 'cucumber_job_emits_event',
        monitored_job_id: roby_controller.last_main_job_id, event_name: event_name.to_sym, timeout: timeout
end
Then(/^the pose is maintained at (.*) with a tolerance of (.*)$/) do |pose, tolerance|
    description = "The pose is maintained at #{pose} with a tolerance of #{tolerance}"
    pose, position_tolerance, orientation_tolerance =
        Cucumber::RockHelpers.parse_pose_and_tolerance(pose, tolerance)
    roby_controller.start_monitoring_job description, 'cucumber_maintain_pose',
        pose: pose, duration: nil,
        position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance
end
Then(/^the pose is maintained at (.*) with a tolerance of (.*) during (.*)$/) do |pose, tolerance, duration|
    pose, position_tolerance, orientation_tolerance = Cucumber::RockHelpers.parse_pose_and_tolerance(pose, tolerance)
    duration, _ = Roby::App::CucumberHelpers.parse_numerical_value(duration)
    roby_controller.run_job 'cucumber_maintain_pose',
        pose: pose, duration: duration,
        position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance
end
