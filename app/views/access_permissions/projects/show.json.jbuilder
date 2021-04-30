# frozen_string_literal: true

json.modal controller.render_to_string(
  partial: 'access_permissions/modals/show_modal',
  formats: [:html],
  locals: {
    resource: @project,
    can_manage_resource: can_manage_project?(@project)
  },
  layout: false
)