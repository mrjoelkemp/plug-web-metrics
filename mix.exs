defmodule Plugwebmetrics.MixProject do
  use Mix.Project

  def project do
    [
      app: :plugwebmetrics,
      version: "1.0.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: ["test.ci": :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    Basic telemetry metrics for a Plug-based, Elixir backend
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Joel Kemp"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mrjoelkemp/plug-web-metrics"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 0.4.1"},
      {:plug_cowboy, "~> 2.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "test.ci": ["test --color --max-cases=10"]
    ]
  end
end
