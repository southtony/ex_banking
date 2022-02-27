defmodule ExBanking.OperationProcessing.PendingOperationsServer do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:state], name: opts[:server_name])
  end

  def init(state), do: {:ok, state}

  def handle_call({:add, op}, _from, state) do
    res = GenServer.cast(state.user_balance_server_name, {:exec_operation, op})

    {:reply, res, state}
  end
end
