defmodule ExBanking.UserServerSupervisor do
  use DynamicSupervisor

  def start_link(_init_args) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_user_server(server_name) do
    registry_server_name = {:via, Registry, {Registry.UserServerNames, server_name}}

    DynamicSupervisor.start_child(
      __MODULE__,
      {ExBanking.UserServer, [server_name: registry_server_name]}
    )
  end
end
