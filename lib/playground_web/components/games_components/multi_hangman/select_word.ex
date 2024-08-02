defmodule PlaygroundWeb.GamesComponents.MultiHangmanComponent.SelectWordChangeset do
  @moduledoc """
  A typed schema for the select word form
  """
  use Playground.DB.Schema
  import Ecto.Changeset

  typed_embedded_schema do
    field :word, :string
  end

  def changeset(room, attrs, opts \\ []) do
    room
    |> cast(attrs, [:word])
    |> validate_required([:word], opts)
    |> validate_length(:word, min: 1, max: 64)
  end
end

defmodule PlaygroundWeb.GamesComponents.MultiHangmanComponent.SelectWord do
  @moduledoc """
  A component for a multiplayer hangman game
  """

  use PlaygroundWeb, :live_component

  alias PlaygroundWeb.GamesComponents.MultiHangmanComponent.SelectWordChangeset

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <%= if @game.state["words"]["#{@player_id}"] do %>
        <.header class="w-full text-center" header_class="text-2xl md:text-4xl font-bold">
          Waiting for others...
        </.header>
        <div class="flex flex-col items-center w-full text-center mt-12 font-md gap-2">
          <div class="text-zinc-700">
            Your word:
          </div>
          <p class="w-3/4 md:w-1/2 rounded-md bg-gray-200 px-5 py-2 font-semibold font-mono text-xl">
            <%= @game.state["words"]["#{@player_id}"] %>
          </p>
        </div>
      <% else %>
        <.header class="w-full text-center" header_class="text-2xl md:text-4xl font-bold">
          Pick Your Secret Word
          <:subtitle>
            Any word you like, but keep it secret!
          </:subtitle>
        </.header>
        <.simple_form
          for={@form}
          id="post-form"
          phx-target={@myself}
          phx-change="select-words-validate"
          phx-submit="select-words-submit"
          phx-hook="CtrlEnterSubmit"
          class="w-full md:w-1/2 mx-auto mt-24"
          autocomplete="off"
        >
          <.input
            field={@form[:word]}
            type="text"
            placeholder="Your secret word"
            class="uppercase"
            phx-mounted={JS.focus()}
          />
          <:actions>
            <div class="w-full flex flex-1 flex-row justify-end">
              <.button phx-disable-with="Submitting...">Submit!</.button>
            </div>
          </:actions>
        </.simple_form>
      <% end %>
    </div>
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    changeset =
      SelectWordChangeset.changeset(
        %SelectWordChangeset{},
        %{word: ""},
        validate_length: false
      )

    {:ok, socket |> assign(assigns) |> assign_form(changeset)}
  end

  @impl Phoenix.LiveComponent
  def handle_event("select-words-validate", %{"select_word" => select_word_params}, socket) do
    changeset =
      SelectWordChangeset.changeset(
        %SelectWordChangeset{},
        select_word_params
      )

    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("select-words-submit", %{"select_word" => select_word_params}, socket) do
    validation =
      %SelectWordChangeset{}
      |> SelectWordChangeset.changeset(select_word_params)
      |> Ecto.Changeset.apply_action(:insert)

    case validation do
      {:ok, _changeset} ->
        notify_parent({:moved, select_word_params["word"] |> String.trim() |> String.upcase()})

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "select_word")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end

  defp notify_parent(msg), do: send(self(), msg)
end
