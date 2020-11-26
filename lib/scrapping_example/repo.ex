defmodule ScrappingExample.Repo do
  use Ecto.Repo,
    otp_app: :scrapping_example,
    adapter: Ecto.Adapters.Postgres
end
