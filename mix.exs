defmodule Playground.MixProject do
  use Mix.Project

  def project do
    [
      app: :playground,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Playground.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bandit, "~> 1.13.1"},
      {:dns_cluster, "~> 0.3.1"},
      {:ecto_sql, "~> 3.14"},
      {:esbuild, "~> 0.10.1", runtime: Mix.env() == :dev},
      {:finch, "~> 0.24"},
      {:floki, ">= 0.38.4", only: :test},
      {:gettext, "~> 1.0.2"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:jason, "~> 1.4"},
      {:phoenix, "~> 1.8.16"},
      {:phoenix_ecto, "~> 4.7"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_dashboard, "~> 0.9.1"},
      {:phoenix_live_reload, "~> 1.7", only: :dev},
      {:phoenix_live_view, "~> 1.2.13"},
      {:postgrex, ">= 0.22.4"},
      {:swarm, "~> 3.4"},
      {:swoosh, "~> 1.29"},
      {:tailwind, "~> 0.5.2", runtime: Mix.env() == :dev},
      {:telemetry_metrics, "~> 1.2"},
      {:telemetry_poller, "~> 1.0"},
      {:typed_ecto_schema, "~> 0.5.0", runtime: false},

      # monitoring
      {:sentry, "~> 14.0"},
      {:hackney, "~> 4.8.6"},

      # Test
      {:ex_machina, "~> 2.8.2", only: [:dev, :test]},

      # Dev
      {:credo, "~> 1.7.19", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.23.0", only: :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind playground", "esbuild playground"],
      "assets.deploy": [
        "tailwind playground --minify",
        "esbuild playground --minify",
        "phx.digest"
      ],
      seeds: ["run priv/repo/seeds.exs"],
      ensure_code_consistency: [
        "credo --strict",
        "dialyzer",
        "doctor",
        "format --check-formatted"
      ]
    ]
  end
end
