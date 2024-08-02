defmodule PlaygroundWeb.GamesComponents.TicTacToeComponent do
  @moduledoc """
  A component for the Tic Tac Toe game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="text-xl md:text-2xl font-bold m-4 text-center">
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
              <.button phx-click="back" size={:responsive} variant={:secondary}>
                Pick another game
              </.button>
              <.button phx-click="again" size={:responsive}>
                Play again
              </.button>
            </div>
          <% @game.state["turn"] == "#{@player_id}" -> %>
            <p>Your turn! You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %></p>
          <% true -> %>
            <p>
              You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %>. Waiting...
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
                      phx-target={@myself}
                      phx-click="move"
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
    notify_parent(
      {:moved, %{row: String.to_integer(row_index), col: String.to_integer(col_index)}}
    )

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), msg)
end
