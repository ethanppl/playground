defmodule PlaygroundWeb.GamesComponents.SuperTicTacToeComponent do
  @moduledoc """
  A component for the Tic Tac Toe game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="text-xl md:text-2xl font-bold m-2 text-center">
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
          <%= Enum.map(0..8, fn board_num -> %>
            <div class="relative">
              <%= case get_cell(@game.state["boards"], "9", floor(board_num/3), rem(board_num, 3)) do %>
                <% nil -> %>
                  <div></div>
                <% "x" -> %>
                  <div class="absolute w-full aspect-square flex item-center z-10">
                    <div class="m-auto w-10/12 aspect-square cross-lg" />
                  </div>
                <% "o" -> %>
                  <div class="absolute w-full aspect-square flex item-center z-10">
                    <div class="m-auto w-10/12 aspect-square circle-lg" />
                  </div>
              <% end %>
              <div class="w-full border-2 solid border-slate-300">
                <div class={[
                  "w-full aspect-square grid grid-cols-3",
                  board_is_disabled?(@game.state, board_num) && "opacity-30",
                  get_cell(@game.state["boards"], "9", floor(board_num / 3), rem(board_num, 3)) != nil &&
                    "opacity-30",
                  @game.state["turn"] != "#{@player_id}" &&
                    not board_is_disabled?(@game.state, board_num) && "opacity-80",
                  @game.state["winner"] != nil && "opacity-30"
                ]}>
                  <%= @game.state["boards"]["#{board_num}"] |> Enum.with_index() |> Enum.map(fn({row, row_index}) -> %>
                    <%= row |> Enum.with_index() |> Enum.map(fn({cell, col_index}) -> %>
                      <%= case cell do %>
                        <% nil -> %>
                          <%= if @game.state["turn"] == "#{@player_id}" and is_nil(@game.state["winner"]) do %>
                            <button
                              class={[
                                "border solid border-slate-300 aspect-square flex item-center cursor-pointer",
                                not board_is_disabled?(@game.state, board_num) && "hover:bg-gray-100"
                              ]}
                              disabled={board_is_disabled?(@game.state, board_num)}
                              phx-target={@myself}
                              phx-click="move"
                              phx-value-row_index={row_index}
                              phx-value-col_index={col_index}
                              phx-value-board_id={board_num}
                            />
                          <% else %>
                            <div class="border solid border-slate-300 aspect-square flex item-center" />
                          <% end %>
                        <% "x" -> %>
                          <div class="border solid border-slate-300 aspect-square flex item-center">
                            <div class="m-auto w-10/12 aspect-square cross" />
                          </div>
                        <% "o" -> %>
                          <div class="border solid border-slate-300 aspect-square flex item-center">
                            <div class="m-auto w-10/12 aspect-square circle" />
                          </div>
                      <% end %>
                    <% end) %>
                  <% end) %>
                </div>
              </div>
            </div>
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
        %{"row_index" => row_index, "col_index" => col_index, "board_id" => board_id},
        socket
      ) do
    notify_parent(
      {:moved,
       %{
         row: String.to_integer(row_index),
         col: String.to_integer(col_index),
         board_id: board_id
       }}
    )

    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), msg)

  def board_is_disabled?(state, board_num) do
    cond do
      state["winner"] != nil ->
        true

      state["next_board"] == "9" and
          is_nil(get_cell(state["boards"], "9", floor(board_num / 3), rem(board_num, 3))) ->
        false

      state["next_board"] == "9" ->
        true

      state["next_board"] == "#{board_num}" ->
        false

      true ->
        true
    end
  end

  def get_cell(boards, board_id, row, column) do
    boards |> Map.get(board_id) |> Enum.at(row) |> Enum.at(column)
  end
end
