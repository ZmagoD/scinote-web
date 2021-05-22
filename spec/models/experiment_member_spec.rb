# frozen_string_literal: true

require 'rails_helper'

describe ExperimentMember, type: :model do
  let(:owner_role) { create :owner_role }
  let!(:user) { create :user }
  let!(:project) { create :project }
  let!(:user_project) { create :user_project, user: user, project: project }
  let!(:user_assignment) {
    create :user_assignment,
           assignable: project,
           user: user,
           user_role: owner_role,
           assigned_by: user
  }
  let!(:experiment) { create :experiment, project: project }
  let(:normal_user_role) { create :normal_user_role }

  let(:subject) { described_class.new(user, experiment, project) }

  describe '#handle_change' do
    let!(:valid_params) {
      {
        user_id: user.id,
        user_role_id: normal_user_role.id
      }
    }

    it 'creates a new user assigment when no assigment present' do
      expect {
        subject.handle_change(valid_params)
      }.to change(UserAssignment, :count).by(1)
    end

    it 'removes the user assigment if the project role is the same as selected one' do
      create :user_assignment, assignable: experiment, user: user, user_role: owner_role, assigned_by: user
      create :user_assignment, assignable: project, user: user, user_role: normal_user_role, assigned_by: user

      expect {
        subject.handle_change(valid_params)
      }.to change(UserAssignment, :count).by(-1)
    end

    it 'updates the assigment user role' do
      assigment = create :user_assignment, assignable: experiment, user: user, user_role: owner_role, assigned_by: user
      subject.handle_change(valid_params)
      expect(assigment.reload.user_role).to eq normal_user_role
    end

    it 'logs a change_user_role_on_experiment activity' do
      expect {
        subject.handle_change(valid_params)
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_experiment'
    end
  end

  describe '#update' do
    let!(:experiment_user_assignment) {
      create :user_assignment,
             assignable: experiment,
             user: user,
             user_role: owner_role,
             assigned_by: user
    }

    let!(:valid_params) {
      {
        user_id: user.id,
        user_role_id: normal_user_role.id
      }
    }

    let!(:subject) { described_class.new(user, experiment, project, user, experiment_user_assignment) }

    it 'updates the assigment user role' do
      subject.update(valid_params)
      expect(experiment_user_assignment.reload.user_role).to eq normal_user_role
    end

    it 'logs a change_user_role_on_my_module activity' do
      expect {
        subject.update(valid_params)
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_experiment'
    end
  end

  describe '#destroy' do
    let!(:experiment_user_assignment) {
      create :user_assignment,
             assignable: experiment,
             user: user,
             user_role: owner_role,
             assigned_by: user
    }

    let!(:subject) { described_class.new(user, experiment, project, user, experiment_user_assignment) }

    it 'destroys the assigment user role' do
      expect {
        subject.destroy
      }.to change(UserAssignment, :count).by(-1)
    end

    it 'logs a change_user_role_on_my_module activity' do
      expect {
        subject.destroy
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_experiment'
    end
  end

  describe '#create' do
    let!(:valid_params) {
      {
        user_id: user.id,
        user_role_id: normal_user_role.id
      }
    }

    let(:subject) { described_class.new(user, experiment, project) }

    it 'creates a new user assigment when no assigment present' do
      expect {
        subject.create(valid_params)
      }.to change(UserAssignment, :count).by(1)
    end

    it 'logs a change_user_role_on_my_module activity' do
      expect {
        subject.create(valid_params)
      }.to change(Activity, :count).by(1)
      expect(Activity.last.type_of).to eq 'change_user_role_on_experiment'
    end
  end
end
