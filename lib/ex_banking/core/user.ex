defmodule ExBanking.Core.User do
  alias ExBanking.Core.ServerManager
  alias ExBanking.Types.Servers.UserBalanceServer

  @spec user_exists(String.t()) :: :user_does_not_exist | :user_exists
  def user_exists(name) do
    case ServerManager.get_server(name, %UserBalanceServer{}) do
      {:ok, _pid} -> :user_exists
      {:error, :server_not_found} -> :user_does_not_exist
    end
  end
end
