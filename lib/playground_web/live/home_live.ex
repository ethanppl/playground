defmodule PlaygroundWeb.HomeLive do
  use PlaygroundWeb, :live_view

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Welcome!")
    |> assign(:room, nil)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, :page_title, "New Room")
  end

  defp apply_action(socket, :join, _params) do
    socket
    |> assign(:page_title, "Join Room")
    |> assign(:room, %{"id" => nil, "room_code" => "", "host_name" => ""})
  end
end
