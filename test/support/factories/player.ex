defmodule Playground.Factories.Player do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def player_factory(%{room_id: _room_id} = overrides) do
        %Playground.DB.Player{
          name: sequence(:player_name, &"Player #{&1}")
        }
        |> merge_attributes(overrides)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
