defmodule PlaygroundWeb.TicTacToeComponent do
  @moduledoc """
  A component for the Tic Tac Toe game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="text-2xl font-bold m-4 w-full text-center">
        <%= cond do %>
          <% not is_nil(@game.state["winner"]) -> %>
            <%= if @game.state["winner"] == "draw" do %>
              <p>
                You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %>. It's a draw!
              </p>
            <% else %>
              <%= if @game.state["winner"] == "#{@player_id}" do %>
                <p>You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %>. You won!</p>
              <% else %>
                <p>
                  You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %>. You lost!
                </p>
              <% end %>
            <% end %>
            <div class="my-4">
              <.button phx-click="tic-tac-toe-again">
                Play again
              </.button>
              <.button phx-click="back">
                Pick another game
              </.button>
            </div>
          <% @game.state["turn"] == "#{@player_id}" -> %>
            <p>Your turn! You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %></p>
          <% true -> %>
            <p>
              You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %>. Waiting for another players...
            </p>
        <% end %>
      </div>

      <div class="flex justify-around">
        <div class="mt-12 w-10/12 aspect-square grid grid-cols-3">
          <%= @game.state["board"] |> Enum.with_index() |> Enum.map(fn({row, row_index}) -> %>
            <%= row |> Enum.with_index() |> Enum.map(fn({cell, col_index}) -> %>
              <%= case cell do %>
                <% nil -> %>
                  <%= if @game.state["turn"] == "#{@player_id}" and is_nil(@game.state["winner"]) do %>
                    <button
                      class="border solid aspect-square flex item-center hover:bg-gray-100 cursor-pointer"
                      phx-click="tic-tac-toe-move"
                      phx-value-row_index={row_index}
                      phx-value-col_index={col_index}
                    />
                  <% else %>
                    <div class="border solid aspect-square flex item-center hover:bg-gray-100" />
                  <% end %>
                <% "x" -> %>
                  <div class="border solid aspect-square flex item-center">
                    <div class="m-auto w-10/12 aspect-square cross" />
                  </div>
                <% "o" -> %>
                  <div class="border solid aspect-square flex item-center">
                    <div class="m-auto w-10/12 aspect-square circle" />
                  </div>
              <% end %>
            <% end) %>
          <% end) %>
        </div>
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "move",
        %{"row_index" => row_index, "col_index" => col_index},
        socket
      ) do
    Playground.RoomProcess.game_move(%{
      code: socket.assigns.room_code,
      player_id: socket.assigns.player_id,
      move: %{row: String.to_integer(row_index), col: String.to_integer(col_index)}
    })

    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event(
        "again",
        _params,
        socket
      ) do
    Playground.RoomProcess.end_game(socket.assigns.room_code)
    Playground.RoomProcess.start_game(%{code: socket.assigns.room_code, game_id: "tic-tac-toe"})

    {:noreply, socket}
  end
end
