# frozen_string_literal: true

require 'cucumber/models/compositions/pose_predicate'
require 'cucumber/models/compositions/reach_pose'

module Cucumber
    module Compositions
        describe PosePredicate do
            describe '#within_tolerance?' do
                attr_reader :pose, :sample, :reach_pose
                before do
                    @pose = Types.base.Pose.new(
                        position: Eigen::Vector3.Zero,
                        orientation: Eigen::Quaternion.Identity
                    )
                    @sample = Types.base.Pose.new(
                        position: Eigen::Vector3.new(1, 2, -3),
                        orientation:
                            Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitZ) *
                            Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitY) *
                            Eigen::Quaternion.from_angle_axis(0.1, Eigen::Vector3.UnitX)
                    )
                    @reach_pose = ReachPose.new(pose: pose)
                end
                it 'returns true if each position\'s axis is within the tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.new(1.1, 2.1, 3.1)
                    reach_pose.orientation_tolerance = Eigen::Vector3.Unset
                    assert reach_pose.within_tolerance?(sample)
                end
                it 'returns false if the X axis is outside the tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.new(0.5, 2.1, 3.1)
                    reach_pose.orientation_tolerance = Eigen::Vector3.Unset
                    refute reach_pose.within_tolerance?(sample)
                end
                it 'returns false if the Y axis is outside the tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.new(1.1, 0.1, 3.1)
                    reach_pose.orientation_tolerance = Eigen::Vector3.Unset
                    refute reach_pose.within_tolerance?(sample)
                end
                it 'returns false if the Z axis is outside the tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.new(1.1, 2.1, 0.1)
                    reach_pose.orientation_tolerance = Eigen::Vector3.Unset
                    refute reach_pose.within_tolerance?(sample)
                end
                it 'ignores position axis whose tolerance is Base.unset' do
                    reach_pose.position_tolerance =
                        Eigen::Vector3.new(1.1, Base.unset, 3.1)
                    reach_pose.orientation_tolerance = Eigen::Vector3.Unset
                    assert reach_pose.within_tolerance?(sample)
                end

                it 'returns true if each orientation\'s angles are within '\
                   'the tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.Unset
                    reach_pose.orientation_tolerance = Eigen::Vector3.new(0.2, 0.2, 0.2)
                    assert reach_pose.within_tolerance?(sample)
                end
                it 'returns false if yaw is outside the specified tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.Unset
                    reach_pose.orientation_tolerance = Eigen::Vector3.new(0.05, 0.2, 0.2)
                    refute reach_pose.within_tolerance?(sample)
                end
                it 'returns false if pitch is outside the specified tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.Unset
                    reach_pose.orientation_tolerance = Eigen::Vector3.new(0.2, 0.05, 0.2)
                    refute reach_pose.within_tolerance?(sample)
                end
                it 'returns false if roll is outside the specified tolerance' do
                    reach_pose.position_tolerance = Eigen::Vector3.Unset
                    reach_pose.orientation_tolerance = Eigen::Vector3.new(0.2, 0.2, 0.05)
                    refute reach_pose.within_tolerance?(sample)
                end
                it 'ignores orientation angles whose tolerance is Base.unset' do
                    reach_pose.position_tolerance = Eigen::Vector3.Unset
                    reach_pose.orientation_tolerance =
                        Eigen::Vector3.new(0.2, Base.unset, 0.2)
                    assert reach_pose.within_tolerance?(sample)
                end
            end
        end
    end
end
