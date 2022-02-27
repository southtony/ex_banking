defmodule ExBanking.OperationProcessing.PendingOperationsServer do
  use GenServer

  alias ExBanking.Types.{
    Operation,
    ServerStates.PendingOperationsServerState
  }

  @max_pending_tasks 10

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:state], name: opts[:server_name])
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:add, %Operation{} = op}, _from, %PendingOperationsServerState{} = state) do
    if :queue.len(state.operations_queue) < @max_pending_tasks do
      new_queue = :queue.in(op, state.operations_queue)

      new_state = %{state | operations_queue: new_queue}

      if :queue.len(state.operations_queue) == 0 do
        GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), op})
      end

      {:reply, :ok, new_state}
    else
      send(op.waiting_client, {:error, :operation_state_full})
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_cast(:ack, %PendingOperationsServerState{} = state) do
    case :queue.out(state.operations_queue) do
      {{:value, _completed_operation}, new_queue} ->
        case :queue.out(new_queue) do
          {{:value, op}, _new_queue} ->
            GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), op})
            new_state = %{state | operations_queue: new_queue}

            {:noreply, new_state}

          {:empty, _} ->
            new_state = %{state | operations_queue: new_queue}
            {:noreply, new_state}
        end

      {:empty, _} ->
        {:noreply, state}
    end
  end
end
