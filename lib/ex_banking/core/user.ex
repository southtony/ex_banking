defmodule ExBanking.Core.User do
  def get_pid_user_server(name) do
    case Registry.lookup(Registry.UserServerNames, name) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :user_server_not_found}
    end
  end
end
