defmodule ExBanking.Core.User do
  alias ExBanking.Core.ServerManager
  alias ExBanking.Types.Servers.UserBalanceServer

  def user_exists(name) do
    case ServerManager.get_server(name, %UserBalanceServer{}) do
      {:ok, _pid} -> :user_exists
      {:error, :server_not_found} -> :user_does_not_exist
    end
  end
end
