defmodule ExBanking.UserServer do
  use GenServer

  def start_link(server_name: server_name) do
    GenServer.start_link(__MODULE__, [], name: server_name)
  end

  @impl true
  def init(_args) do
    {:ok, []}
  end
end
