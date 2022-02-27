defmodule ExBanking.ServersManagerSupervisor do
  use DynamicSupervisor

  alias ExBanking.OperationProcessing.{
    PendingOperationsServer,
    UserBalanceServer
  }

  alias ExBanking.Types.ServerStates.PendingOperationsServerState

  alias ExBanking.Settings.Queue.ErlQueue

  def start_link(_init_args), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_init_args), do: DynamicSupervisor.init(strategy: :one_for_one)

  def add_user(name) do
    user_balance_server_name = reg_server_name(name)
    queue_impl = ErlQueue.impl()

    with {:ok, _pid} <-
           start_server(UserBalanceServer, server_name: user_balance_server_name, state: %{}),
         {:ok, _pid} <-
           start_server(
             PendingOperationsServer,
             server_name: reg_server_name(name, "PendingOperations"),
             state: %PendingOperationsServerState{
               user_balance_server_name: user_balance_server_name,
               operations_queue: queue_impl.new(),
               queue_impl: queue_impl,
               operations_limit: 10
             }
           ) do
      :ok
    end
  end

  defp reg_server_name(name, prefix \\ "") do
    full_name = prefix <> name

    {:via, Registry, {Registry.ServerNames, full_name}}
  end

  defp start_server(module, args) do
    DynamicSupervisor.start_child(__MODULE__, {module, args})
  end
end
