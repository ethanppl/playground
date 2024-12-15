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

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Welcome!")
    |> assign(:room, nil)
    |> maybe_put_flash(params)
  end

  defp apply_action(socket, :new, _params) do
    assign(socket, :page_title, "New Room")
  end

  defp apply_action(socket, :join, params) do
    room_code = Map.get(params, "code", "")

    socket
    |> assign(:page_title, "Join Room")
    |> assign(:room, %{"id" => nil, "room_code" => room_code, "host_name" => ""})
  end

  defp maybe_put_flash(socket, %{"error" => error}) do
    # A bit more safe
    sliced_error = String.slice(error, 0..120)

    put_flash(socket, :error, sliced_error)
  end

  defp maybe_put_flash(socket, _params) do
    socket
  end
end
