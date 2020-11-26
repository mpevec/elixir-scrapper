defmodule ScrappingExample.Application do
  use Application

  def start(_type, _args) do
    children = [ScrappingExample.Repo]

    opts = [strategy: :one_for_one, name: ScrappingExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
