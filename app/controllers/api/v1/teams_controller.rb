# frozen_string_literal: true

module Api
  module V1
    class TeamsController < BaseController
      before_action :load_team, only: :show

      def index
        teams = current_user.teams
                            .page(params.dig(:page, :number))
                            .per(params.dig(:page, :size))
        render jsonapi: teams, each_serializer: TeamSerializer
      end

      def show
        render jsonapi: @team, serializer: TeamSerializer, include: :created_by
      end

      private

      def load_team
        @team = Team.find(params.require(:id))
        permission_error(Team, :read) unless can_read_team?(@team)
      end
    end
  end
end
