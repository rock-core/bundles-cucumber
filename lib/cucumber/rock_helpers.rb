require 'roby/app/cucumber/helpers'
module Cucumber
    module RockHelpers
        def self.parse_pose(pose_text)
            args = Roby::App::CucumberHelpers.parse_arguments(pose_text)
            hash_to_pose(args)
        end

        def self.hash_to_pose(args, default_position: 0)
            position = hash_xyz_to_vector3(args, default: default_position)
            orientation = Eigen::Quaternion.from_angle_axis(args.fetch(:yaw, 0), Eigen::Vector3.UnitZ) *
                Eigen::Quaternion.from_angle_axis(args.fetch(:pitch, 0), Eigen::Vector3.UnitY) *
                Eigen::Quaternion.from_angle_axis(args.fetch(:roll, 0), Eigen::Vector3.UnitX)
            Types.base.Pose.new(position: position, orientation: orientation)
        end

        def self.hash_xyz_to_vector3(args, default: 0)
            v = Eigen::Vector3.new
            v.x = args.fetch(:x, default)
            v.y = args.fetch(:y, default)
            v.z = args.fetch(:z, default)
            v
        end

        def self.parse_pose_and_tolerance(pose_text, tolerance_text)
            pose_args = Roby::App::CucumberHelpers.parse_arguments(pose_text)
            tolerance_args = Roby::App::CucumberHelpers.
                parse_arguments_respectively(pose_args.keys, tolerance_text)

            pose = hash_to_pose(pose_args, default_position: 0)
            position_tolerance = hash_xyz_to_vector3(tolerance_args, default: Float::INFINITY)

            orientation_tolerance = Eigen::Vector3.new
            orientation_tolerance.x = tolerance_args.fetch(:yaw, Float::INFINITY)
            orientation_tolerance.y = tolerance_args.fetch(:pitch, Float::INFINITY)
            orientation_tolerance.z = tolerance_args.fetch(:roll, Float::INFINITY)
            return pose, position_tolerance, orientation_tolerance
        end

        def self.massage_action_name(action_name, action_kind)
            action_name = action_name.gsub(/\s/, '_')
            if action_kind == 'definition'
                "#{action_name}_def"
            else action_name
            end
        end
    end
end

