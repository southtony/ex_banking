defmodule ExBanking.OperationProcessing.UserPoolWorker do
  use GenServer

  def start_link(user_server_name) do
    GenServer.start_link(__MODULE__, user_server_name)
  end

  def init(_user_server_name) do
    {:ok, []}
  end

  def handle_call({:exec_operation, operation}, _from, state) do

  end
end
