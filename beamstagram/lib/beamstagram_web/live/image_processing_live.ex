defmodule BeamstagramWeb.ImageProcessingLive do
  use BeamstagramWeb, :live_view

  defmodule FilterParams do
    use Ecto.Schema

    @primary_key false
    embedded_schema do
      field(:filter, Ecto.Enum,
        values: [nil, :gaussian_blur, :uniform_blur, :sharpen, :tint],
        default: nil
      )

      field(:tint_r, :integer, default: 255)
      field(:tint_g, :integer, default: 255)
      field(:tint_b, :integer, default: 255)
      field(:tint_alpha, :float, default: 0.2)

      field(:kernel_size, :integer, default: 3)
      field(:sigma, :float, default: 1.0)

      field(:blur_kernel, Ecto.Enum,
        values: [:gaussian_blur, :uniform_blur],
        default: :gaussian_blur
      )

      field(:should_recompile, :boolean, default: true)
    end

    def changeset(data \\ %__MODULE__{}, params) do
      changeset =
        Ecto.Changeset.cast(data, params, [
          :filter,
          :kernel_size,
          :sigma,
          :blur_kernel,
          :tint_r,
          :tint_g,
          :tint_b,
          :tint_alpha
        ])

      tint_field = Ecto.Changeset.get_field(changeset, :filter) == :tint
      tint_change = Ecto.Changeset.get_change(changeset, :filter) == :tint

      should_recompile = not tint_field or (tint_change and not (data.filter == :tint))

      Ecto.Changeset.put_change(changeset, :should_recompile, should_recompile)
    end
  end

  def mount(_params, _session, socket) do
    changeset = FilterParams.changeset(%{})

    filter_params = Ecto.Changeset.apply_changes(changeset)

    filter_form =
      to_form(changeset, as: :filter_form)

    filter_options = [
      None: nil,
      "Gaussian Blur": :gaussian_blur,
      "Uniform Blur": :uniform_blur,
      Sharpen: :sharpen,
      Tint: :tint
    ]

    blur_kernel_options = [
      "Gaussian Blur": :gaussian_blur,
      "Uniform Blur": :uniform_blur
    ]

    {:ok,
     assign(socket,
       frames: [],
       predictions: %{},
       total_bytes: 0,
       total_seconds: 0,
       bytecode: nil,
       start_time: System.monotonic_time(:second),
       filter_form: filter_form,
       filter_options: filter_options,
       blur_kernel_options: blur_kernel_options,
       filter_params: filter_params
     )}
  end

  defp compile(%FilterParams{filter: nil}), do: nil

  defp compile(%FilterParams{} = filter_params) do
    iree_compiler_flags = [
      "--iree-hal-target-backends=llvm-cpu",
      "--iree-input-type=stablehlo",
      "--iree-llvmcpu-target-triple=wasm32-unknown-emscripten",
      "--iree-llvmcpu-target-cpu-features=+atomics,+bulk-memory,+simd128"
    ]

    function = Beamstagram.Filters.build(Map.from_struct(filter_params))

    template =
      if filter_params.filter == :tint do
        [
          Nx.template({480, 640, 4}, :u8),
          Nx.template({4}, :f32)
        ]
      else
        [Nx.template({480, 640, 4}, :u8)]
      end

    {:ok, %{bytecode: bytecode}} =
      NxIREE.Compiler.to_bytecode(
        function,
        template,
        iree_compiler_flags: iree_compiler_flags
      )

    bytecode
  end

  def render(assigns) do
    assigns =
      if assigns.filter_params.filter == :tint do
        assign(assigns, :tint_params, [
          assigns.filter_params.tint_r,
          assigns.filter_params.tint_g,
          assigns.filter_params.tint_b,
          assigns.filter_params.tint_alpha
        ])
      else
        assign(assigns, :tint_params, nil)
      end

    ~H"""
    <div id="wasm-webcam-container" phx-hook="WasmWebcamHook">
      <video
        data-bytecode={if(@bytecode, do: Base.encode64(@bytecode), else: "")}
        data-filter-kind={@filter_params.filter}
        id="wasm-webcam"
        width="640"
        height="480"
        autoplay
      >
      </video>
      <meta id="tint-params" content={Jason.encode!(@tint_params)} />
      <canvas
        {if(@bytecode, do: %{"style" => "display: none"}, else: %{})}
        id="wasm-webcam-input"
        width="640"
        height="480"
      >
      </canvas>
      <canvas
        id="wasm-webcam-output"
        {if(@bytecode, do: %{}, else: %{"style" => "display: none"})}
        width="640"
        height="480"
      >
      </canvas>
    </div>

    <.form for={@filter_form} phx-change="update_filter">
      <.label for="filter">Filter</.label>
      <.input type="select" name="filter" value={@filter_params.filter} options={@filter_options} />

      <div :if={@filter_params.filter in [:gaussian_blur, :uniform_blur, :sharpen]}>
        <.label for="kernel_size">Kernel Size</.label>
        <.input type="number" name="kernel_size" value={@filter_params.kernel_size} />
      </div>

      <div :if={@filter_params.filter in [:gaussian_blur, :sharpen]}>
        <.label for="sigma">Sigma</.label>
        <.input type="range" name="sigma" value={@filter_params.sigma} step="0.5" min="0.1" max="50" />
      </div>

      <div :if={@filter_params.filter == :sharpen}>
        <.label for="blur_kernel">Blur Kernel</.label>
        <.input
          type="select"
          name="blur_kernel"
          value={@filter_params.blur_kernel}
          options={@blur_kernel_options}
          disabled={@filter_params.filter != :sharpen}
        />
      </div>

      <div :if={@filter_params.filter == :tint}>
        <.label for="tint_r">Tint Red</.label>
        <.input
          type="range"
          phx-throttle="500"
          name="tint_r"
          value={@filter_params.tint_r}
          step="1"
          min="0"
          max="255"
        />

        <.label for="tint_g">Tint Green</.label>
        <.input
          type="range"
          phx-throttle="500"
          name="tint_g"
          value={@filter_params.tint_g}
          step="1"
          min="0"
          max="255"
        />

        <.label for="tint_b">Tint Blue</.label>
        <.input
          type="range"
          phx-throttle="500"
          name="tint_b"
          value={@filter_params.tint_b}
          step="1"
          min="0"
          max="255"
        />

        <.label for="tint_alpha">Tint Alpha</.label>
        <.input
          phx-throttle="500"
          type="range"
          name="tint_alpha"
          value={@filter_params.tint_alpha}
          step="0.1"
          min="0"
          max="1"
        />
      </div>
    </.form>
    """
  end

  def handle_event("update_filter", %{"_target" => [target]} = params, socket) do
    value = params[target]

    changeset =
      FilterParams.changeset(socket.assigns.filter_params, %{target => value})

    filter_form = to_form(changeset, as: :filter_form)

    filter_params = Ecto.Changeset.apply_changes(changeset)

    bytecode =
      if filter_params.should_recompile do
        compile(filter_params)
      else
        socket.assigns.bytecode
      end

    # Update assigns for compilation
    assigns = %{
      filter_params: filter_params,
      filter_form: filter_form,
      bytecode: bytecode
    }

    {:noreply, assign(socket, assigns)}
  end
end
