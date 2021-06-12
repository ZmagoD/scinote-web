# frozen_string_literal: true
require 'rails_helper'

module UserAssignments
  RSpec.describe GenerateUserAssignmentsJob, type: :job do
    let!(:owner_role) { create :owner_role }
    let!(:viewer_role) { create :viewer_role }
    let!(:technician_role) { create :technician_role }

    let!(:user_one) { create :user }
    let!(:user_two) { create :user }
    let!(:user_three) { create :user }
    let!(:team) { create :team, created_by: user_one }
    let!(:project) { create :project, team: team, created_by: user_one }

    before do
      available_roles = [owner_role, viewer_role, technician_role]
      [user_one, user_two, user_three].each_with_index do |user, i|
        create :user_team, :admin, user: user, team: team
        create :user_project, user: user, project: project
        create :user_assignment,
               assignable: project,
               user: user,
               user_role: available_roles[i],
               assigned_by: user
      end
    end

    describe 'perform' do
      context 'experiment' do
        let!(:experiment) { create :experiment, project: project }

        it 'creates user assignments for all users on the project that are not assigned yet' do
          expect {
            described_class.perform_now(experiment, user_one)
          }.to change(UserAssignment, :count).by(3)
        end

        it 'assigns the same role as the user had on project level' do
          described_class.perform_now(experiment, user_one)
          user_two_assignment = UserAssignment.find_by(user: user_two, assignable: experiment)
          user_three_assignment = UserAssignment.find_by(user: user_three, assignable: experiment)
          expect(user_two_assignment.user_role).to eq viewer_role
          expect(user_three_assignment.user_role).to eq technician_role
        end
      end

      context 'my_module' do
        let!(:experiment) { create :experiment, project: project }
        let!(:my_module) { create :my_module, experiment: experiment }

        it 'creates user assignments for all users on the project that are not assigned yet' do
          expect {
            described_class.perform_now(my_module, user_one)
          }.to change(UserAssignment, :count).by(3)
        end

        it 'assigns the same role as the user had on project level' do
          described_class.perform_now(my_module, user_one)
          user_two_assignment = UserAssignment.find_by(user: user_two, assignable: my_module)
          user_three_assignment = UserAssignment.find_by(user: user_three, assignable: my_module)
          expect(user_two_assignment.user_role).to eq viewer_role
          expect(user_three_assignment.user_role).to eq technician_role
        end
      end
    end
  end
end