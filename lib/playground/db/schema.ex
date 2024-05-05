defmodule Playground.DB.Schema do
  @moduledoc """
  A wrapper around `Ecto.Schema`

  use TypedEctoSchema
  import Ecto.Changeset
  alias Ecto.Query
  require Ecto.Query
  """
  defmacro __using__(_opts) do
    quote do
      use TypedEctoSchema
      import Ecto.Changeset
      alias Ecto.Query
      require Ecto.Query
    end
  end
end
