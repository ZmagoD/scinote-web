class UserMyModulesController < ApplicationController
  before_action :load_vars
  before_action :check_view_permissions, only: %i(index index_old index_edit)
  before_action :check_manage_permissions, only: %i(create destroy)

  def index_old
    @user_my_modules = @my_module.user_my_modules

    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'index_old.html.erb'
          ),
          my_module_id: @my_module.id,
          counter: @my_module.users.count # Used for counter badge
        }
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        render json: {
          html: render_to_string(
            partial: 'index.html.erb'
          )
        }
      end
    end
  end

  def index_edit
    @user_my_modules = @my_module.user_my_modules
    @unassigned_users = @my_module.unassigned_users
    @new_um = UserMyModule.new(my_module: @my_module)

    respond_to do |format|
      format.json do
        render json: {
          my_module: @my_module,
          html: render_to_string(
            partial: 'index_edit.html.erb'
          )
        }
      end
    end
  end

  def create
    @um = UserMyModule.new(um_params.merge(my_module: @my_module))
    @um.assigned_by = current_user

    if @um.save
      log_activity(:assign_user_to_module)

      respond_to do |format|
        format.json do
          render json: {
            user: {
              id: @um.user.id,
              full_name: @um.user.full_name,
              avatar_url: avatar_path(@um.user, :icon_small),
              user_module_id: @um.id
            }, status: :ok
          }
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            errors: @um.errors
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    if @um.destroy
      log_activity(:unassign_user_from_module)

      respond_to do |format|
        format.json do
          render json: {}, status: :ok
        end
      end
    else
      respond_to do |format|
        format.json do
          render json: {
            errors: @um.errors
          }, status: :unprocessable_entity
        end
      end
    end
  end

  def search
    assigned_users = @my_module.user_my_modules.pluck(:user_id)
    all_users = @my_module.experiment.project.users
    users = all_users.where.not(id: assigned_users)
                     .search(false, params[:query])
                     .limit(6)

    users = users.map do |user|
      {
        value: user.id,
        label: sanitize_input(user.full_name),
        params: { avatar_url: avatar_path(user, :icon_small) }
      }
    end

    render json: users
  end

  private

  include InputSanitizeHelper

  def load_vars
    @my_module = MyModule.find_by_id(params[:my_module_id])

    if @my_module
      @project = @my_module.experiment.project
    else
      render_404
    end

    if action_name == "destroy"
      @um = UserMyModule.find_by_id(params[:id])
      unless @um
        render_404
      end
    end
  end

  def check_view_permissions
    render_403 unless can_read_experiment?(@my_module.experiment)
  end

  def check_manage_permissions
    render_403 unless can_manage_users_in_module?(@my_module)
  end

  def um_params
    params.require(:user_my_module).permit(:user_id, :my_module_id)
  end

  def log_activity(type_of)
    Activities::CreateActivityService
      .call(activity_type: type_of,
            owner: current_user,
            team: @um.my_module.experiment.project.team,
            project: @um.my_module.experiment.project,
            subject: @um.my_module,
            message_items: { my_module: @my_module.id,
                             user_target: @um.user.id })
  end
end
