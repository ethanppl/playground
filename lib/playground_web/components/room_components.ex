defmodule PlaygroundWeb.RoomComponents do
  use Phoenix.Component

  alias PlaygroundWeb.CoreComponents

  def players_component(assigns) do
    ~H"""
    <p class="w-full text-center text-sm leading-6 text-zinc-600">
      <%= PlaygroundWeb.RoomLive.players_count(@room) %>
      <%= if PlaygroundWeb.RoomLive.players_count(@room) > 1,
        do: "players",
        else: "player. Invite others!" %>
    </p>
    <div class="mt-2 flex flex-row flex-wrap justify-around">
      <div :for={player <- @room.players} class="flex flex-col gap-0 items-center">
        <CoreComponents.icon name="hero-user-solid" class="w-6 h-6 mb-2" />
        <span class="text-sm text-zinc-900"><%= player.name %></span>
        <span
          :if={player.id == @room.host_id}
          class="inline-flex items-center rounded-md bg-blue-50 mx-2 px-2 py-1 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10"
        >
          HOST
        </span>
      </div>
    </div>
    """
  end
end
