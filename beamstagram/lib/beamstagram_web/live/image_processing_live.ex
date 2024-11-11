defmodule BeamstagramWeb.ImageProcessingLive do
  use BeamstagramWeb, :live_view

  import Nx.Defn

  def mount(_params, _session, socket) do
    bytecode = compile(socket.assigns)

    {:ok,
     assign(socket,
       frames: [],
       predictions: %{},
       total_bytes: 0,
       total_seconds: 0,
       bytecode: bytecode,
       start_time: System.monotonic_time(:second)
     )}
  end

  deftransform uniform_blur_kernel(kernel_size) do
    Nx.broadcast(1 / kernel_size ** 2, {kernel_size, kernel_size})
  end

  defn gaussian_blur_kernel(opts \\ []) do
    opts = keyword!(opts, [:size, :sigma])

    size =
      case opts[:size] do
        s when Elixir.Kernel.rem(s, 2) == 0 -> s + 1
        s -> s
      end

    sigma = opts[:sigma]

    half_size = div(size, 2)

    range = {size} |> Nx.iota() |> Nx.subtract(half_size)

    x = Nx.vectorize(range, :x)
    y = Nx.vectorize(range, :y)

    # Apply Gaussian function to each element
    kernel =
      Nx.exp(-(x * x + y * y) / (2 * sigma * sigma))

    kernel = kernel / (2 * Nx.Constants.pi() * sigma * sigma)

    kernel = Nx.devectorize(kernel)

    # Normalize the kernel so the sum is 1
    kernel / Nx.sum(kernel)
  end

  defn sharpen_kernel(opts \\ []) do
    blur_kernel =
      case opts[:blur_kernel] do
        :uniform -> uniform_blur_kernel(opts[:size])
        _ -> gaussian_blur_kernel(opts)
      end

    shape = Nx.shape(blur_kernel)

    eye = Nx.eye(shape)
    identity_kernel = Nx.reverse(eye, axes: [0]) * eye

    2 * identity_kernel - blur_kernel
  end

  defp compile(assigns) do
    iree_compiler_flags = [
      "--iree-hal-target-backends=llvm-cpu",
      "--iree-input-type=stablehlo",
      "--iree-llvmcpu-target-triple=wasm32-unknown-emscripten",
      "--iree-llvmcpu-target-cpu-features=+atomics,+bulk-memory,+simd128"
    ]

    kernel_size = assigns[:kernel_size] || 7

    {:ok, %{bytecode: bytecode}} =
      NxIREE.Compiler.to_bytecode(
        fn image ->
          image
          |> Nx.as_type(:f32)
          |> Nx.window_mean({kernel_size, kernel_size, 1}, padding: :same)
          |> Nx.as_type(:u8)
        end,
        [Nx.template({480, 640, 4}, :u8)],
        iree_compiler_flags: iree_compiler_flags
      )

    bytecode
  end

  def render(assigns) do
    ~H"""
    <div id="wasm-webcam-container" phx-hook="WasmWebcamHook">
      <video
        data-bytecode={Base.encode64(@bytecode)}
        id="wasm-webcam"
        width="640"
        height="480"
        autoplay
      >
      </video>
      <canvas style="display: none" id="wasm-webcam-input" width="640" height="480"></canvas>
      <canvas id="wasm-webcam-output" width="640" height="480"></canvas>
    </div>
    """
  end
end
