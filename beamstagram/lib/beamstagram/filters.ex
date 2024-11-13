defmodule Beamstagram.Filters do
  import Nx.Defn

  deftransform build(opts) do
    case opts[:filter] do
      :sharpen ->
        kernel =
          sharpen_kernel(
            kernel_size: opts[:kernel_size],
            blur_kernel: opts[:blur_kernel],
            sigma: opts[:sigma]
          )

        &apply_kernel(&1, kernel)

      :gaussian_blur ->
        kernel =
          gaussian_blur_kernel(
            kernel_size: opts[:kernel_size],
            sigma: opts[:sigma]
          )

        &apply_kernel(&1, kernel)

      :uniform_blur ->
        kernel = uniform_blur_kernel(kernel_size: opts[:kernel_size])
        &apply_kernel(&1, kernel)

      :tint ->
        &tint_image/2
    end
  end

  defn tint_image(image, tint) do
    alpha = tint[3]

    colors = image[[.., .., 0..2]]
    tint_hues = Nx.broadcast(tint[0..2], Nx.shape(colors))

    tinted_colors = Nx.clip(colors + (tint_hues - colors) * alpha, 0, 255)

    tinted_colors = Nx.as_type(tinted_colors, :u8)

    Nx.concatenate([tinted_colors, image[[.., .., 3..3]]], axis: 2)
  end

  deftransform get_odd_size(opts) do
    size = opts[:kernel_size]
    size + 1 - rem(size, 2)
  end

  defn uniform_blur_kernel(opts \\ []) do
    opts = keyword!(opts, [:kernel_size])
    size = get_odd_size(opts)

    Nx.broadcast(1 / size ** 2, {size, size})
  end

  defn gaussian_blur_kernel(opts \\ []) do
    opts = keyword!(opts, [:kernel_size, :sigma])

    size = get_odd_size(opts)

    sigma =
      case opts[:sigma] do
        nil -> raise "sigma is required"
        sigma -> sigma
      end

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

  defn apply_kernel(image, kernel, opts \\ []) do
    opts = keyword!(opts, strides: [1, 1])

    # assumes channels are last in the image
    input_type = Nx.type(image)
    image = image / 255

    {m, n} = Nx.shape(kernel)

    image
    # |> extend_outward(padding_x: div(m, 2), padding_y: div(n, 2))
    |> Nx.new_axis(0)
    |> Nx.conv(Nx.reshape(kernel, {1, 1, m, n}),
      padding: :same,
      input_permutation: [3, 0, 1, 2],
      output_permutation: [3, 0, 1, 2],
      strides: opts[:strides]
    )
    |> Nx.squeeze(axes: [0])
    |> Nx.multiply(255)
    |> Nx.clip(0, 255)
    |> Nx.as_type(input_type)
  end

  defn sharpen_kernel(opts \\ []) do
    blur_kernel =
      case opts[:blur_kernel] do
        :uniform -> uniform_blur_kernel(kernel_size: opts[:kernel_size])
        _ -> gaussian_blur_kernel(kernel_size: opts[:kernel_size], sigma: opts[:sigma])
      end

    shape = Nx.shape(blur_kernel)

    eye = Nx.eye(shape)
    identity_kernel = Nx.reverse(eye, axes: [0]) * eye

    2 * identity_kernel - blur_kernel
  end
end
