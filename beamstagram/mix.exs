defmodule Beamstagram.MixProject do
  use Mix.Project

  def project do
    [
      app: :beamstagram,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Beamstagram.Application, []},
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
      {:phoenix, "~> 1.7.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.2"},
      {:stb_image, "~> 0.1"},
      {:exla, "~> 0.9.1"},
      {:nx_iree, github: "elixir-nx/nx_iree", branch: "main"},
      {:live_view_native, "~> 0.3.0"},
      {:live_view_native_stylesheet, "~> 0.3.0"},
      {:live_view_native_swiftui, "~> 0.3.0"},
      {:live_view_native_live_form, "~> 0.3.0"}
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
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": [
        "tailwind.install --if-missing",
        "esbuild.install --if-missing",
        "beamstagram.install_wasm"
      ],
      "assets.build": ["tailwind beamstagram", "esbuild beamstagram", "beamstagram.deploy_wasm"],
      "assets.deploy": [
        "tailwind beamstagram --minify",
        "esbuild beamstagram --minify",
        "beamstagram.deploy_wasm",
        "phx.digest"
      ],
      "beamstagram.install_wasm": &install_wasm/1,
      "beamstagram.deploy_wasm": &deploy_wasm/1
    ]
  end

  defp install_wasm(_) do
    assets_dir = "assets/js"

    {_, 0} = System.cmd("make", ["webassembly"], cd: "deps/nx_iree")
    install_dir = "./deps/nx_iree/iree-runtime/webassembly/install"

    for file <- ["nx_iree_runtime.wasm", "nx_iree_runtime.mjs"] do
      File.cp!(Path.join(install_dir, file), Path.join(assets_dir, file))
    end
  end

  defp deploy_wasm(_) do
    File.mkdir_p!("priv/static/assets")
    File.cp!("assets/js/nx_iree_runtime.wasm", "priv/static/assets/nx_iree_runtime.wasm")
  end
end
