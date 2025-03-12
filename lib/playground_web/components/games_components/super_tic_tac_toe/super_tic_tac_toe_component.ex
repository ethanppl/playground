defmodule PlaygroundWeb.GamesComponents.SuperTicTacToeComponent do
  @moduledoc """
  A component for the Tic Tac Toe game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="text-xl md:text-2xl font-bold mb-2 text-center">
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
            <div class="py-4 flex flex-row justify-center gap-2">
              <.button phx-click="back" size={:sm} variant={:secondary}>
                Pick another game
              </.button>
              <.button phx-click="again" size={:sm}>
                Play again
              </.button>
            </div>
          <% @game.state["turn"] == "#{@player_id}" -> %>
            <p>Your turn! You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %></p>
            <div class="mt-8 text-sm font-normal font-mono text-slate-500 w-full flex flex-row justify-around">
              <%= @current %>
            </div>
          <% true -> %>
            <p>
              You are <%= String.upcase(@game.state["players"]["#{@player_id}"]) %>. Waiting...
            </p>
            <div class="mt-8 text-sm font-normal font-mono text-slate-500 w-full flex flex-row justify-around">
              <%= @current %>
            </div>
        <% end %>
      </div>

      <div class="mt-2 text-sm font-mono text-slate-500 w-full flex flex-row justify-around">
        <div class="flex flex-row gap-4">
          <span><%= find_player_name(@players, @game.state["symbols"]["x"]) %></span>
          <span><%= @x_cumulative %></span>
        </div>
        <div class="flex flex-row gap-4">
          <span><%= find_player_name(@players, @game.state["symbols"]["o"]) %></span>
          <span><%= @o_cumulative %></span>
        </div>
      </div>

      <div class="flex justify-around">
        <div class="mt-6 w-10/12 aspect-square grid grid-cols-3 border-2 solid border-slate-900">
          <%= Enum.map(0..8, fn board_num -> %>
            <!-- Each small board -->
            <div class="relative">
              <%!-- The overlay on each small board --%>
              <%= case get_cell(@game.state["boards"], "9", floor(board_num/3), rem(board_num, 3)) do %>
                <% nil -> %>
                  <% nil %>
                <% "x" -> %>
                  <div class="absolute w-full aspect-square flex item-center z-10">
                    <div class="m-auto w-10/12 aspect-square cross-lg" />
                  </div>
                <% "o" -> %>
                  <div class="absolute w-full aspect-square flex item-center z-10">
                    <div class="m-auto w-10/12 aspect-square circle-lg" />
                  </div>
              <% end %>
              <%!-- The grids for each small board --%>
              <div class="w-full border solid border-slate-900">
                <div class={
                  [
                    # Basic classes
                    "w-full aspect-square grid grid-cols-3",
                    # When the board is disabled
                    board_is_disabled?(@game.state, board_num) && "opacity-40 bg-slate-300",
                    # When the board is enabled, but the viewer is not the player
                    @game.state["turn"] != "#{@player_id}" &&
                      not board_is_disabled?(@game.state, board_num) && "opacity-80"
                  ]
                }>
                  <%= @game.state["boards"]["#{board_num}"] |> Enum.with_index() |> Enum.map(fn({row, row_index}) -> %>
                    <%= row |> Enum.with_index() |> Enum.map(fn({cell, col_index}) -> %>
                      <!-- Each small cell -->
                      <div class={[
                        "border solid border-slate-600 aspect-square flex item-center",
                        cell_is_previous_move?(@game.state, board_num, row_index, col_index) &&
                          "bg-green-300"
                      ]}>
                        <%= case cell do %>
                          <% nil -> %>
                            <%= if @game.state["turn"] == "#{@player_id}" and is_nil(@game.state["winner"]) and not board_is_disabled?(@game.state, board_num) do %>
                              <button
                                class="flex flex-grow cursor-pointer hover:bg-gray-100"
                                phx-target={@myself}
                                phx-click="move"
                                phx-value-row_index={row_index}
                                phx-value-col_index={col_index}
                                phx-value-board_id={board_num}
                              />
                            <% end %>
                          <% "x" -> %>
                            <div class="m-auto w-10/12 aspect-square cross" />
                          <% "o" -> %>
                            <div class="m-auto w-10/12 aspect-square circle" />
                        <% end %>
                      </div>
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
    # First cancel any tick timer
    # If a tick is needed, schedule tick will schedule one new
    # If a tick is not needed, prevents previous timer from overriding states
    cancel_tick_timer(socket)

    timer_data = get_timer_data(assigns.game.state)

    tick_timer =
      if is_nil(assigns.game.state["winner"]) do
        schedule_tick(assigns)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(timer_data)
     |> assign(tick_timer: tick_timer)}
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

  defp schedule_tick(assigns) do
    send_update_after(
      self(),
      __MODULE__,
      assigns,
      1000
    )
  end

  defp cancel_tick_timer(%Phoenix.LiveView.Socket{assigns: %{tick_timer: tick_timer}})
       when is_reference(tick_timer) do
    Process.cancel_timer(tick_timer)
  end

  defp cancel_tick_timer(_socket) do
    false
  end

  defp get_timer_data(state) do
    timer = state["timer"]
    turn = state["turn"]
    symbol = state["players"][turn]

    now = Time.utc_now()
    current = Time.from_iso8601!(timer[symbol]["current"])

    diff =
      if is_nil(state["winner"]) do
        Time.diff(now, current)
      else
        0
      end

    cumulative_assigns =
      if symbol == "x" do
        %{
          x_cumulative: seconds_to_string(timer["x"]["cumulative"] + diff),
          o_cumulative: seconds_to_string(timer["o"]["cumulative"])
        }
      else
        %{
          x_cumulative: seconds_to_string(timer["x"]["cumulative"]),
          o_cumulative: seconds_to_string(timer["o"]["cumulative"] + diff)
        }
      end

    cumulative_assigns
    |> Map.merge(%{current: seconds_to_string(diff)})
    |> Map.merge(%{id: :super_tic_tac_toe})
  end

  defp notify_parent(msg), do: send(self(), msg)

  def board_is_disabled?(state, board_num) do
    cond do
      # All boards are disabled when there is a winner
      state["winner"] != nil ->
        true

      # If the next board is the whole board
      # And this board is not filled in the big board
      # Then the board is not disabled
      state["next_board"] == "9" and
          is_nil(get_cell(state["boards"], "9", floor(board_num / 3), rem(board_num, 3))) ->
        false

      # If the next board is the whole board
      # And this board is filled in the big board
      # Then the board is disabled
      state["next_board"] == "9" ->
        true

      # If the next board is this board, then not disabled
      state["next_board"] == "#{board_num}" ->
        false

      # If the next board is not this board, then disabled
      true ->
        true
    end
  end

  def cell_is_previous_move?(
        %{"previous_move" => %{"board_id" => board_id, "row" => row, "col" => col}},
        board_id_int,
        row,
        col
      ) do
    String.to_integer(board_id) == board_id_int
  end

  def cell_is_previous_move?(_state, _board_id, _row, _col) do
    false
  end

  def get_cell(boards, board_id, row, column) do
    boards |> Map.get(board_id) |> Enum.at(row) |> Enum.at(column)
  end

  defp find_player_name(players, player_id) when is_binary(player_id) do
    {integer_player_id, _remainder} = Integer.parse(player_id)

    case Enum.find(players, fn player -> player.id == integer_player_id end) do
      nil -> ""
      %Playground.DB.Player{name: name} -> name
    end
  end

  defp find_player_name(players, integer_player_id) do
    case Enum.find(players, fn player -> player.id == integer_player_id end) do
      nil -> ""
      %Playground.DB.Player{name: name} -> name
    end
  end

  defp seconds_to_string(seconds) do
    minute = trunc(seconds / 60)
    sec = rem(seconds, 60)

    "#{pad_num(minute)}:#{pad_num(sec)}"
  end

  defp pad_num(num) do
    num
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end
end
