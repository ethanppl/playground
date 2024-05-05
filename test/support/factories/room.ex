defmodule Playground.Factories.Room do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def room_factory(overrides) do
        {:ok, code} = Playground.Rooms.generate_code()

        %Playground.DB.Room{
          code: code
        }
        |> merge_attributes(overrides)
        |> evaluate_lazy_attributes()
      end
    end
  end
end
