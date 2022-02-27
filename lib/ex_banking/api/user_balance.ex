defmodule ExBanking.API.UserBalance do
  alias ExBanking.Core.ServerManager

  alias ExBanking.Types.{
    Operation,
    Servers
  }

  def execute(user, %Operation{} = op) do
    {:ok, pid} = ServerManager.get_server(user, %Servers.PendingOperationsServer{})
    GenServer.call(pid, {:add, op})

    receive do
      msg -> msg
    end
  end
end
