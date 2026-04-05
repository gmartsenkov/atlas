defmodule AtlasWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use AtlasWeb, :html

  embed_templates "error_html/*"

  # Fallback for non-customized error pages (e.g. 500)
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
