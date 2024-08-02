defmodule PlaygroundWeb.CollapsibleComponent do
  @moduledoc false
  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="w-full mt-1">
      <button
        class="w-full hover:bg-zinc-100 border-b border-solid rounded-t py-2 px-6 font-semibold text-sm flex justify-between"
        phx-target={@myself}
        phx-click="toggle"
      >
        <div class="w-11/12 text-left"><%= render_slot(@header) %></div>
        <%= if @collapsed do %>
          <.icon name="hero-chevron-left" class="h-4 w-4" />
        <% else %>
          <.icon name="hero-chevron-down" class="h-4 w-4" />
        <% end %>
      </button>
      <%= if not @collapsed do %>
        <div class="w-full bg-zinc-50 border-solid rounded-b p-6 text-sm">
          <%= render_slot(@body) %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def update(%{collapsed: _collapsed} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(collapsed: true)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, collapsed: !socket.assigns.collapsed)}
  end
end
