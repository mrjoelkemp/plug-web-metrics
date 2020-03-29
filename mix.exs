defmodule Plugwebmetrics.MixProject do
  use Mix.Project

  def project do
    [
      app: :plugwebmetrics,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
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
      {:plug_cowboy, "~> 2.1"}
    ]
  end
end
