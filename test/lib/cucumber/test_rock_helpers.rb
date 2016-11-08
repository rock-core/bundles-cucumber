require 'cucumber/rock_helpers'

module Cucumber
    describe RockHelpers do
        before do
            app.import_types_from 'base'
        end

        describe ".parse_pose" do
            it "returns a pose with the relevant translation fields filled" do
                pose = RockHelpers.parse_pose("x=10m, y=15m and z=20m")
                assert_equal Eigen::Vector3.new(10, 15, 20), pose.position
            end

            it "leaves unset translation fields to Base.unset" do
                pose = RockHelpers.parse_pose("x=10m and z=20m")
                assert_equal 10, pose.position.x
                assert Base.unset?(pose.position.y)
                assert_equal 20, pose.position.z
            end

            it "returns the identity orientation if no other rotations are provided" do
                pose = RockHelpers.parse_pose("x=10m, y=15m and z=20m")
                assert_equal Eigen::Quaternion.Identity, pose.orientation
            end

            it "applies the yaw, pitch and roll angles" do
                pose = RockHelpers.parse_pose("yaw=1deg, pitch=2deg and roll=3deg")
                radians = Eigen::Vector3.new(*[1, 2, 3].map { |deg| deg * Math::PI / 180 })
                assert (radians - pose.orientation.to_euler).norm < 1e-4
            end

            it "applies zero for missing angles" do
                pose = RockHelpers.parse_pose("yaw=1deg and roll=3deg")
                radians = Eigen::Vector3.new(*[1, 0, 3].map { |deg| deg * Math::PI / 180 })
                assert (radians - pose.orientation.to_euler).norm < 1e-4
            end
        end

        describe ".parse_pose_and_tolerance" do
            it "returns a pose and the corresponding tolerance with the relevant translation fields filled" do
                pose, position_tolerance, orientation_tolerance =
                    RockHelpers.parse_pose_and_tolerance("x=10m, y=15m and z=20m", "1m, 2m and 3m")
                assert_equal Eigen::Vector3.new(10, 15, 20), pose.position
                assert_equal Eigen::Vector3.new(1, 2, 3), position_tolerance
            end

            it "leaves pose and tolerance fields to unset if they are not set" do
                pose, position_tolerance, orientation_tolerance =
                    RockHelpers.parse_pose_and_tolerance("x=10m and z=20m", "1m and 3m")
                assert_equal 10, pose.position.x
                assert Base.unset?(pose.position.y)
                assert_equal 20, pose.position.z
                assert_equal 1, position_tolerance.x
                assert Base.unset?(position_tolerance.y)
                assert_equal 3, position_tolerance.z
            end

            it "leaves orientation tolerance fields as rpy" do
                pose, position_tolerance, orientation_tolerance =
                    RockHelpers.parse_pose_and_tolerance("yaw=1deg, pitch=2deg and roll=3deg", "0.1deg, 0.2deg and 0.3deg")
                radians = Eigen::Vector3.new(*[1, 2, 3].map { |deg| deg * Math::PI / 180 })
                assert (radians - pose.orientation.to_euler).norm < 1e-4
                radians = Eigen::Vector3.new(*[0.1, 0.2, 0.3].map { |deg| deg * Math::PI / 180 })
                assert (radians - orientation_tolerance).norm < 1e-4
            end

            it "leaves orientation fields to unset if they are not provided" do
                pose, position_tolerance, orientation_tolerance =
                    RockHelpers.parse_pose_and_tolerance("yaw=1deg and roll=3deg", "0.1deg and 0.3deg")
                radians = Eigen::Vector3.new(*[1, 0, 3].map { |deg| deg * Math::PI / 180 })
                assert (radians - pose.orientation.to_euler).norm < 1e-4
                assert_in_delta 0.1 * Math::PI / 180, orientation_tolerance.x, 1e-4
                assert Base.unset?(orientation_tolerance.y)
                assert_in_delta 0.3 * Math::PI / 180, orientation_tolerance.z, 1e-4
            end
        end
    end
end
