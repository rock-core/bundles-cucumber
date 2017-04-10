require 'cucumber/rock_helpers'

Given(/^the (\w+) robot starting at (.*) in (?:the )?(.*)$/) do |robot_name, start_position, world|
    if start_position == 'origin'
        start_position = Hash[x: 0, y: 0, z: 0, yaw: 0]
    else
        start_position = Roby::App::CucumberHelpers.parse_arguments(start_position, Cucumber::RockHelpers::POSE_QUANTITIES, strict: true)
    end
    world = world.gsub(/\s/, '_')
    roby_controller.roby_start robot_name, robot_name,
        state: Hash['sdf.world_path' => world, 'gazebo.localhost' => true]
    gazebo_start world, working_directory: roby_controller.roby_log_dir

    roby_controller.run_job 'cucumber_settle'

    x, y, z, yaw = start_position.values_at(:x, :y, :z, :yaw)
    pose = Types.base.Pose.new(
        position: Eigen::Vector3.new(x || 0, y || 0, z || 0),
        orientation: Eigen::Quaternion.from_angle_axis(yaw || 0, Eigen::Vector3.UnitZ))
    warp_job = roby_controller.start_job "Warping the robot", 'cucumber_warp_robot',
        pose: pose
    roby_controller.run_job 'cucumber_reach_pose',
        pose: pose, position_tolerance: Eigen::Vector3.new(0.01, 0.01, 0.5),
        orientation_tolerance: Eigen::Vector3.new(0.001, 0.001, 0.001), timeout: 10
    # The warp job is not a monitoring job, it's not automatically stopped by run_job
    if !roby_controller.validation_mode?
        roby_controller.drop_jobs warp_job
    end
end
When(/^after (.*)$/) do |delay|
    delay, _ = Roby::App::CucumberHelpers.parse_numerical_value(delay, :time)
    roby_controller.apply_current_batch
    if !roby_controller.validation_mode?
        start = Time.now
        roby_controller.roby_poll_interface_until do
            Time.now - start > delay
        end
    end
end

Then(/^it stays still during (.*) with a tolerance of (.*)$/) do |duration, pose_tolerance|
    position_tolerance, orientation_tolerance = Cucumber::RockHelpers.parse_pose_tolerance(pose_tolerance)
    duration, _ = Roby::App::CucumberHelpers.parse_numerical_value(duration)
    roby_controller.run_job 'cucumber_stays_still',
        position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance,
        acquisition_timeout: 5,
        duration: duration
end
When(/^it runs the (.*) (action|definition)$/) do |action_name, action_kind|
    action_name = Cucumber::RockHelpers.massage_action_name(action_name, action_kind)
    roby_controller.start_job "When it runs #{action_name}",
        action_name
end
When(/^it runs the (.*) (action|definition) with (.*)$/) do |action_name, action_kind, raw_arguments|
    action_name = Cucumber::RockHelpers.massage_action_name(action_name, action_kind)
    arguments   = Roby::App::CucumberHelpers.parse_arguments(raw_arguments, strict: false)
    roby_controller.start_job "When it runs #{action_name} with #{raw_arguments}",
        action_name, **arguments
end
Then(/^the pose reaches (.*) with a tolerance of (.*) within (.*)$/) do |pose, tolerance, timeout|
    pose, position_tolerance, orientation_tolerance = Cucumber::RockHelpers.parse_pose_and_tolerance(pose, tolerance)
    $last_reaches_step = [pose, position_tolerance, orientation_tolerance]
    timeout, _ = Roby::App::CucumberHelpers.parse_numerical_value(timeout)
    roby_controller.run_job 'cucumber_reach_pose',
        pose: pose, position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance, timeout: timeout
end
Then(/^it stays there for (.*)$/) do |duration|
    if !$last_reaches_step
        raise ArgumentError, "can only use 'it stays there for Xs' after a 'the pose reaches ...' step"
    end

    pose, position_tolerance, orientation_tolerance = *$last_reaches_step
    duration, _ = Roby::App::CucumberHelpers.parse_numerical_value(duration, :time)
    roby_controller.run_job 'cucumber_maintain_pose',
        pose: pose, duration: duration,
        position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance
end

Then(/^it (?:is|has) (.*) within (.*)$/) do |event_name, timeout|
    timeout, _ = Roby::App::CucumberHelpers.parse_numerical_value(timeout)
    roby_controller.apply_current_batch
    last_job_id = roby_controller.last_main_job_id
    if !last_job_id && !roby_controller.validation_mode?
        raise "no main job started, on which to wait for event #{event_name}"
    end
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
Then(/^the pose is maintained during (.*) at (.*) with a tolerance of (.*)$/) do |duration, pose, tolerance|
    pose, position_tolerance, orientation_tolerance = Cucumber::RockHelpers.parse_pose_and_tolerance(pose, tolerance)
    duration, _ = Roby::App::CucumberHelpers.parse_numerical_value(duration, :time)
    roby_controller.run_job 'cucumber_maintain_pose',
        pose: pose, duration: duration,
        position_tolerance: position_tolerance,
        orientation_tolerance: orientation_tolerance
end
