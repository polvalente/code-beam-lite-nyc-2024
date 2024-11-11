defmodule Beamstagram.Repo do
  use Ecto.Repo,
    otp_app: :beamstagram,
    adapter: Ecto.Adapters.Postgres
end
