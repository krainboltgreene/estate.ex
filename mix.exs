defmodule Estate.MixProject do
  use Mix.Project

  def project do
    [
      app: :estate,
      version: "1.0.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: "A macro that gives ecto schema modules behavior relating to state machines",
      package: %{
        links: %{"GitHub" => "https://github.com/krainboltgreene/estate.ex"},
        licenses: ["Hippocratic-3.0"]
      },
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.8"}
    ]
  end
end
