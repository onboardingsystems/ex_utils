defmodule ExUtils.Mixfile do
  use Mix.Project

  def project do
    [app: :ex_utils,
     version: "1.0.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     compilers: [:gettext] ++ Mix.compilers,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {ExUtils, []},
     applications: [:logger, :poolboy, :redix, :poison, :cowboy, :phoenix, :phoenix_pubsub, :gettext]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:poolboy, "~> 1.5"},
     {:redix, "~> 0.4.0"},
     {:poison, "~> 2.2"},
     {:ecto, "~> 2.0"},
     {:cowboy, "~> 1.0"},
     {:phoenix, "~> 1.2"},
     {:phoenix_pubsub, "~> 1.0"},
     {:gettext, "~> 0.11"}]
  end
end
