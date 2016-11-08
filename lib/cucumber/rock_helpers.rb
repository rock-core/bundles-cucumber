require 'roby/app/cucumber/helpers'
module Cucumber
    module RockHelpers
        def self.parse_pose(pose_text)
            args = Roby::App::CucumberHelpers.parse_arguments(pose_text)
            hash_to_pose(args)
        end

        def self.hash_to_pose(args)
            position = hash_xyz_to_vector3(args)
            orientation = Eigen::Quaternion.from_angle_axis(args.fetch(:yaw, 0), Eigen::Vector3.UnitZ) *
                Eigen::Quaternion.from_angle_axis(args.fetch(:pitch, 0), Eigen::Vector3.UnitY) *
                Eigen::Quaternion.from_angle_axis(args.fetch(:roll, 0), Eigen::Vector3.UnitX)
            Types.base.Pose.new(position: position, orientation: orientation)
        end

        def self.hash_xyz_to_vector3(args)
            v = Eigen::Vector3.Unset
            v.x = args[:x] if args[:x]
            v.y = args[:y] if args[:y]
            v.z = args[:z] if args[:z]
            v
        end

        def self.parse_pose_and_tolerance(pose_text, tolerance_text)
            pose_args = Roby::App::CucumberHelpers.parse_arguments(pose_text)
            tolerance_args = Roby::App::CucumberHelpers.
                parse_arguments_respectively(pose_args.keys, tolerance_text)

            pose = hash_to_pose(pose_args)
            position_tolerance = hash_xyz_to_vector3(tolerance_args)

            orientation_tolerance = Eigen::Vector3.Unset
            orientation_tolerance.x = tolerance_args[:yaw] if tolerance_args[:yaw]
            orientation_tolerance.y = tolerance_args[:pitch] if tolerance_args[:pitch]
            orientation_tolerance.z = tolerance_args[:roll] if tolerance_args[:roll]

            return pose, position_tolerance, orientation_tolerance
        end
    end
end

