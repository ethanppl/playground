defmodule Playground.Repo do
  use Ecto.Repo,
    otp_app: :playground,
    adapter: Ecto.Adapters.Postgres

  @app :playground

  @impl Ecto.Repo
  def init(_context, config) do
    if Application.get_env(@app, :in_migration, false) do
      {:ok,
       Keyword.put(
         config,
         :url,
         System.fetch_env!("MIGRATION_DATABASE_URL")
       )}
    else
      {:ok, config}
    end
  end
end
