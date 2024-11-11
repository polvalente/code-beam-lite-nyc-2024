defmodule BeamstagramWeb.ErrorJSONTest do
  use BeamstagramWeb.ConnCase, async: true

  test "renders 404" do
    assert BeamstagramWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert BeamstagramWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
