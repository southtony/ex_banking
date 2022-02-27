defmodule ExBanking.Core.ServerManager do
  alias ExBanking.Types.Servers.{
    PendingOperationsServer,
    UserBalanceServer
  }

  @spec get_server(String.t(), UserBalanceServer.t()) ::
          {:ok, pid()} | {:error, :server_not_found}
  def get_server(name, %UserBalanceServer{}), do: _get_server(name)

  @spec get_server(String.t(), PendingOperationsServer.t()) ::
          {:ok, pid()} | {:error, :server_not_found}
  def get_server(name, %PendingOperationsServer{}) do
    _get_server(name, "PendingOperations")
  end

  defp _get_server(name, prefix \\ "") do
    case Registry.lookup(Registry.ServerNames, prefix <> name) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :server_not_found}
    end
  end
end
