defmodule BeamstagramWeb.Layouts.SwiftUI do
  use BeamstagramNative, [:layout, format: :swiftui]

  embed_templates "layouts_swiftui/*"
end
