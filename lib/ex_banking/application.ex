defmodule ExBanking.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Registry.UserServerNames},
      {DynamicSupervisor, strategy: :one_for_one, name: ExBanking.UserServerSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ExBanking.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
