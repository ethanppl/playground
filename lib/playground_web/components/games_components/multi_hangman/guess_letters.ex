defmodule PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersChangeset do
  @moduledoc """
  A typed schema for the guess letters form
  """
  use Playground.DB.Schema
  import Ecto.Changeset

  typed_embedded_schema do
    field :letter, :string
  end

  def changeset(room, attrs, opts \\ []) do
    room
    |> cast(attrs, [:letter])
    |> validate_required([:letter], opts)
    |> validate_length(:letter, min: 1, max: 1)
  end
end

defmodule PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessWordsChangeset do
  @moduledoc """
  A typed schema for the guess words form
  """
  use Playground.DB.Schema
  import Ecto.Changeset

  typed_embedded_schema do
    field :word, :string
    field :target, :string
  end

  def changeset(room, attrs, opts \\ []) do
    room
    |> cast(attrs, [:word, :target])
    |> validate_required([:word, :target], opts)
    |> validate_length(:word, min: 1)
  end
end

defmodule PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersLetter do
  @moduledoc """
  A component for a multiplayer hangman game
  """

  use PlaygroundWeb, :live_component

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class={[
      "px-1 py-1 rounded flex items-center",
      @variant == "mine_revealed" && "bg-green-100",
      @variant == "mine_not_revealed" && "bg-gray-200",
      @variant == "others_revealed_publicly" && "bg-green-200",
      @variant == "others_revealed_privately" && "bg-green-100",
      @variant == "others_not_revealed" && "bg-gray-300",
      @variant == "history_correct" && "bg-green-200",
      @variant == "history_incorrect" && "bg-red-200"
    ]}>
      <code class="font-semibold text-base">
        <span class={[
          @variant == "mine_revealed" && "text-green-500",
          @variant == "mine_not_revealed" && "text-zinc-400",
          @variant == "others_revealed_publicly" && "text-green-900",
          @variant == "others_revealed_privately" && "text-green-500",
          @variant == "others_not_revealed" && "text-zinc-900",
          @variant == "history_correct" && "text-green-900",
          @variant == "history_incorrect" && "text-red-900"
        ]}>
          <%= if @letter_guess != nil do %>
            <%= @letter %>
          <% else %>
            <%= if @is_player || @type == "history" || @variant == "others_revealed_privately" do %>
              <%= @letter %>
            <% else %>
              ?
            <% end %>
          <% end %>
        </span>
      </code>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    is_publicly_guessed = assigns.letter_guess != nil
    is_privately_guessed = assigns.word_guess["guessed_correctly"]
    is_player = assigns.is_player

    variant =
      cond do
        assigns.type == "secret" and is_player and is_publicly_guessed ->
          "mine_revealed"

        assigns.type == "secret" and is_player and not is_publicly_guessed ->
          "mine_not_revealed"

        assigns.type == "secret" and not is_player and is_publicly_guessed ->
          "others_revealed_publicly"

        assigns.type == "secret" and not is_player and not is_publicly_guessed and
            is_privately_guessed ->
          "others_revealed_privately"

        assigns.type == "secret" and not is_player and not is_publicly_guessed ->
          "others_not_revealed"

        assigns.type == "history" and assigns.is_correct ->
          "history_correct"

        assigns.type == "history" and not assigns.is_correct ->
          "history_incorrect"
      end

    {:ok, socket |> assign(assigns) |> assign(variant: variant)}
  end
end

defmodule PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLetters do
  @moduledoc """
  A component for a multiplayer hangman game
  """

  use PlaygroundWeb, :live_component

  alias PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersChangeset
  alias PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessWordsChangeset

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <div class="h-32 md:h-48 mb-8 flex flex-col items-center">
        <%= if @is_ended do %>
          <div class="flex flex-col items-center justify-center gap-8 h-full w-full rounded">
            <.header class="w-full text-center" header_class="text-4xl font-bold">
              Good game!
            </.header>
            <div class="flex flex-row gap-4 items-center">
              <.button phx-click="back" size={:responsive} variant={:secondary}>
                Pick another game
              </.button>
              <.button phx-click="again" size={:responsive}>
                Play again
              </.button>
            </div>
          </div>
        <% else %>
          <.header class="w-full text-center" header_class="text-4xl font-bold">
            Guess!
          </.header>
          <div class="flex flex-col items-center justify-center h-full w-full rounded">
            <%= if @game.state["turn"] == @player_id and not @is_won do %>
              <.simple_form
                for={@letter_form}
                id="letter-form"
                phx-target={@myself}
                phx-change="guess-letter-validate"
                phx-submit="guess-letter-submit"
                phx-hook="CtrlEnterSubmit"
                class="w-full"
                autocomplete="off"
              >
                <div class="flex flex-row flex-wrap gap-4 w-full items-end md:items-center justify-between my-8">
                  <.input
                    ignore_error_msg
                    field={@letter_form[:letter]}
                    type="text"
                    placeholder="Guess a letter"
                    class="uppercase text-xs font-mono md:text-base !mt-0 !w-36 md:!w-48"
                  />
                  <div>
                    <.button
                      disabled={not @letter_form.source.valid?}
                      phx-disable-with="Submitting..."
                      class="!w-20 md:!w-32"
                      size={:responsive}
                    >
                      Submit
                    </.button>
                  </div>
                </div>
              </.simple_form>
            <% else %>
              <div class="flex flex-row gap-2">
                <span>Waiting</span>
                <span class="font-semibold font-mono">
                  <%= find_player_name(@players, @game.state["turn"]) %>
                </span>
                <div class="relative h-6 w-5">
                  <span class="absolute left-1 animate-bounce">.</span>
                  <span class="absolute left-3 animate-bounce animate-delay-100">.</span>
                  <span class="absolute left-5 animate-bounce animate-delay-200">.</span>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
      <div>
        <%= for {id, word} <- Map.to_list(@game.state["words"]) do %>
          <div
            class="w-full mt-4 px-1 py-2 hover:bg-zinc-100 border-b border-solid rounded-t font-semibold text-sm flex flex-col gap-3"
            phx-click="open_guess_word_modal"
            phx-target={@myself}
            phx-value-id={id}
          >
            <div class="w-full flex flex-row justify-between items-center gap-2">
              <div class="flex flex-1 flex-row gap-2">
                <div class="my-auto w-24 break-word">
                  <%= find_player_name(@players, id) %>
                </div>
                <div class="hidden md:flex md:flex-row md:flex-wrap md:justify-between">
                  <div class="flex flex-1 flex-row flex-wrap gap-1">
                    <%= for idx <- 0..String.length(word) - 1 do %>
                      <.live_component
                        id={"multi_hangman_guess_letters_letter_" <> id <> "#{idx}"}
                        module={
                          PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersLetter
                        }
                        type="secret"
                        letter={String.at(word, idx)}
                        letter_guess={@game.state["letter_guesses"][String.at(word, idx)]}
                        word_guess={@game.state["word_guesses"]["#{@player_id}"][id]}
                        is_player={id == "#{@player_id}"}
                      />
                    <% end %>
                  </div>
                </div>
              </div>
              <div>
                <.button
                  phx-click="open_guess_word_modal"
                  phx-target={@myself}
                  phx-value-id={id}
                  class="!py-0 !w-16 md:!w-24"
                  variant={
                    if id == "#{@player_id}" or
                         @game.state["word_guesses"]["#{@player_id}"][id]["guessed_correctly"],
                       do: :secondary,
                       else: :primary
                  }
                  size={:responsive}
                >
                  <%= cond do %>
                    <% id == "#{@player_id}" -> %>
                      Details
                    <% @game.state["word_guesses"]["#{@player_id}"][id]["guessed_correctly"] -> %>
                      Correct
                    <% true -> %>
                      Guess
                  <% end %>
                </.button>
              </div>
            </div>
            <div class="flex flex-1 flex-row flex-wrap gap-1 md:hidden">
              <%= for idx <- 0..String.length(word) - 1 do %>
                <.live_component
                  id={"multi_hangman_guess_letters_letter_mobile_" <> id <> "#{idx}"}
                  module={PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersLetter}
                  type="secret"
                  letter={String.at(word, idx)}
                  letter_guess={@game.state["letter_guesses"][String.at(word, idx)]}
                  word_guess={@game.state["word_guesses"]["#{@player_id}"][id]}
                  is_player={id == "#{@player_id}"}
                />
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
      <.header header_class="text-lg md:text-xl font-bold mt-16">
        Previous Guesses
      </.header>
      <div class="my-2 md:my-4">
        <%= if Enum.count(@game.state["players_letter_guesses"]) == 0 do %>
          <span class="text-zinc-400 text-xs md:text-sm">
            <i>No guesses yet</i>
          </span>
        <% else %>
          <div class="flex flex-row flex-start flex-wrap gap-4">
            <%= for {%{"is_correct" => is_correct, "letter" => guess, "player" => player_id}, idx} <- @game.state["players_letter_guesses"] |> Enum.reverse() |> Enum.with_index() do %>
              <div class="flex flex-col items-center gap-1">
                <.live_component
                  id={"multi_hangman_guess_history_" <> "#{idx}#{player_id}"}
                  module={PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersLetter}
                  type="history"
                  is_correct={is_correct}
                  letter={guess}
                  letter_guess={nil}
                  word_guess={nil}
                  is_player={player_id == "#{@player_id}"}
                />
                <span class="text-xs text-zinc-400">
                  <%= find_player_name(@players, player_id) %>
                </span>
              </div>
            <% end %>
          </div>
          <div class="mt-6">
            <i class="text-sm text-zinc-400">
              <%= Enum.count(@game.state["players_letter_guesses"]) %>
              <%= if Enum.count(@game.state["players_letter_guesses"]) > 1 do %>
                guesses
              <% else %>
                guess
              <% end %>
              so far
            </i>
          </div>
        <% end %>
      </div>
      <.modal
        :if={@guess_word_modal_data != nil}
        id="guess-word-modal"
        show
        class="min-h-[50vh]"
        on_cancel={JS.push("close_guess_word_modal", target: @myself)}
      >
        <div class="my-8 w-full h-8 flex justify-center">
          <div class="flex flex-row gap-1">
            <%= for idx <- 0..String.length(@game.state["words"][@guess_word_modal_data.id]) - 1 do %>
              <.live_component
                id={"multi_hangman_guess_letters_letter_" <> @guess_word_modal_data.id <> "#{idx}"}
                module={PlaygroundWeb.GamesComponents.MultiHangmanComponent.GuessLettersLetter}
                type="secret"
                letter={String.at(@game.state["words"][@guess_word_modal_data.id], idx)}
                letter_guess={
                  @game.state["letter_guesses"][
                    String.at(@game.state["words"][@guess_word_modal_data.id], idx)
                  ]
                }
                word_guess={@game.state["word_guesses"]["#{@player_id}"][@guess_word_modal_data.id]}
                is_player={@guess_word_modal_data.id == "#{@player_id}"}
              />
            <% end %>
          </div>
        </div>
        <div>
          <%= if @guess_word_modal_data.id == "#{@player_id}" do %>
            <.header header_class="text-base md:text-xl font-bold">
              Attempts
            </.header>
            <div class="mt-14">
              <dl class="-my-4 divide-y divide-zinc-100">
                <div
                  :for={{player_id, player_guess} <- @opponent_guess}
                  class="flex gap-4 py-4 text-sm leading-6 sm:gap-8"
                >
                  <dt class="w-1/3 md:w-1/6 my-1 flex-none font-semibold font-mono">
                    <%= find_player_name(@players, player_id) %>
                  </dt>
                  <dd>
                    <%= if Enum.count(player_guess["history"]) == 0 do %>
                      <span class="text-zinc-400">
                        <i>No guesses yet</i>
                      </span>
                    <% else %>
                      <span
                        :for={word <- Enum.reverse(player_guess["history"])}
                        class={[
                          "px-2 py-1 rounded-xl m-1 text-xs md:text-sm font-semibold inline-block",
                          word == @game.state["words"]["#{@player_id}"] &&
                            "bg-green-100 text-green-900",
                          word != @game.state["words"]["#{@player_id}"] &&
                            "bg-red-100 text-red-900"
                        ]}
                      >
                        <%= word %>
                      </span>
                    <% end %>
                  </dd>
                </div>
              </dl>
            </div>
          <% else %>
            <%= if @game.state["word_guesses"]["#{@player_id}"][@guess_word_modal_data.id]["guessed_correctly"] do %>
              <.header header_class="text-base md:text-xl font-bold mt-8 md:mt-16">
                Your guess is correct!
              </.header>
            <% else %>
              <.form
                for={@word_form}
                id={"word-form-#{@guess_word_modal_data.id}"}
                phx-target={@myself}
                phx-change="guess-word-validate"
                phx-submit="guess-word-submit"
                phx-hook="CtrlEnterSubmit"
                autocomplete="off"
              >
                <div class="flex flex-row flex-wrap gap-4 w-full items-end md:items-center justify-between my-8 md:my-16">
                  <div class="flex flex-row">
                    <.input
                      ignore_error_msg
                      field={@word_form[:target]}
                      type="text"
                      class="hidden"
                      value={@guess_word_modal_data.id}
                    />
                    <.input
                      ignore_error_msg
                      field={@word_form[:word]}
                      type="text"
                      placeholder="Guess the word"
                      class="uppercase text-xs font-mono md:text-base !mt-0 !w-60 md:!w-96"
                    />
                  </div>
                  <div>
                    <.button phx-disable-with="Submitting..." size={:responsive}>
                      Submit!
                    </.button>
                  </div>
                </div>
              </.form>
            <% end %>
            <.header header_class="text-base md:text-xl font-bold mt-8 md:mt-16">
              Attempts
            </.header>
            <div class="flex flex-row flex-wrap mt-4 text-xs md:text-sm leading-6">
              <%= if Enum.count(@game.state["word_guesses"]["#{@player_id}"][@guess_word_modal_data.id]["history"]) == 0 do %>
                <span class="text-zinc-400">
                  <i>No guesses yet</i>
                </span>
              <% else %>
                <span
                  :for={
                    word <-
                      Enum.reverse(
                        @game.state["word_guesses"]["#{@player_id}"][@guess_word_modal_data.id][
                          "history"
                        ]
                      )
                  }
                  class={[
                    "py-1 px-2 rounded-xl m-1 font-semibold",
                    word == @game.state["words"][@guess_word_modal_data.id] &&
                      "bg-green-100 text-green-900",
                    word != @game.state["words"][@guess_word_modal_data.id] &&
                      "bg-red-100 text-red-900"
                  ]}
                >
                  <%= word %>
                </span>
              <% end %>
            </div>
          <% end %>
        </div>
      </.modal>
      <%!-- <pre>
        <%= inspect(@game.state, pretty: true) %>
      </pre> --%>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    letter_changeset =
      GuessLettersChangeset.changeset(
        %GuessLettersChangeset{},
        %{letter: ""},
        validate_length: false
      )

    word_changeset =
      GuessWordsChangeset.changeset(
        %GuessWordsChangeset{},
        %{word: ""},
        validate_length: false
      )

    opponent_guess =
      assigns.game.state["word_guesses"]
      |> Map.delete("#{assigns.player_id}")
      |> Map.to_list()
      |> Enum.map(fn {player_id, word_guess} ->
        {player_id, word_guess["#{assigns.player_id}"]}
      end)

    is_won =
      Playground.Games.MultiHangman.is_player_won?(assigns.game.state, assigns.player_id)

    is_ended =
      Enum.count(assigns.game.state["winners"]) == Enum.count(assigns.players)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_letter_form(letter_changeset)
     |> assign_word_form(word_changeset)
     |> assign(%{
       guess_word_modal_data: nil,
       opponent_guess: opponent_guess,
       is_won: is_won,
       is_ended: is_ended
     })}
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

  @impl Phoenix.LiveComponent
  def handle_event("guess-letter-validate", %{"guess_letter" => guess_letter_params}, socket) do
    changeset =
      GuessLettersChangeset.changeset(
        %GuessLettersChangeset{},
        guess_letter_params
      )

    {:noreply, assign_letter_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("guess-letter-submit", %{"guess_letter" => guess_letter_params}, socket) do
    validation =
      %GuessLettersChangeset{}
      |> GuessLettersChangeset.changeset(guess_letter_params)
      |> Ecto.Changeset.apply_action(:insert)

    case validation do
      {:ok, _changeset} ->
        notify_parent(
          {:moved,
           %{"type" => "letter", "letter" => String.upcase(guess_letter_params["letter"])}}
        )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  def handle_event("open_guess_word_modal", %{"id" => id}, socket) do
    {:noreply, assign(socket, guess_word_modal_data: %{id: id})}
  end

  def handle_event("close_guess_word_modal", _params, socket) do
    {:noreply, assign(socket, guess_word_modal_data: nil)}
  end

  def handle_event("guess-word-validate", %{"guess_word" => guess_word_params}, socket) do
    changeset =
      GuessWordsChangeset.changeset(
        %GuessWordsChangeset{},
        guess_word_params
      )

    {:noreply, assign_word_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("guess-word-submit", %{"guess_word" => guess_word_params}, socket) do
    validation =
      %GuessWordsChangeset{}
      |> GuessWordsChangeset.changeset(guess_word_params)
      |> Ecto.Changeset.apply_action(:insert)

    case validation do
      {:ok, _changeset} ->
        notify_parent(
          {:moved,
           %{
             "type" => "word",
             "word" => guess_word_params["word"] |> String.trim() |> String.upcase(),
             "target_player_id" => guess_word_params["target"]
           }}
        )

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp assign_letter_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "guess_letter")

    assign(socket, letter_form: form)
  end

  defp assign_word_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "guess_word")

    assign(socket, word_form: form)
  end

  defp notify_parent(msg), do: send(self(), msg)
end
