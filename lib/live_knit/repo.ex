defmodule LiveKnit.Repo do
  use Ecto.Repo, otp_app: :live_knit, adapter: Ecto.Adapters.SQLite3
end
