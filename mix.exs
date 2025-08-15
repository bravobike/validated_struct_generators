defmodule ValidatedStructGenerators.MixProject do
  use Mix.Project

  @version "0.0.2"
  @github_page "https://github.com/bravobike/validated_struct_generators"

  def project do
    [
      app: :validated_struct_generators,
      version: "0.0.2",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),

      # doc
      name: "ValidatedStruct Generators",
      description: "A library that provides stream data generators for validated structs",
      homepage_url: @github_page,
      source_url: @github_page,
      docs: docs(),
      package: package()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "dev", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:stream_data, "~> 1.0"},
      {:type_resolver, "~> 0.1.7"},
      {:validated_struct, "~> 0.0.1"}
    ]
  end

  defp docs() do
    [
      api_reference: false,
      authors: ["Simon Härer, Norbert Melzer"],
      canonical: "http://hexdocs.pm/validated_struct_generators",
      main: "ValidatedStruct Generators",
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      files: ~w(mix.exs README.md lib .formatter.exs),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @github_page},
      maintainers: ["Simon Härer, Norbert Melzer"]
    ]
  end
end
