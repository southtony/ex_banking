defmodule ExBanking.OperationProcessing.PendingOperationsServer do
  use GenServer

  alias ExBanking.Types.{
    Operation,
    ServerStates.PendingOperationsServerState
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:state], name: opts[:server_name])
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:add, %Operation{} = op}, _from, %PendingOperationsServerState{} = state) do
    if state.queue_impl.length(state.operations_queue) < state.operations_limit do
      new_queue = state.queue_impl.enqueue(op, state.operations_queue)

      new_state = %{state | operations_queue: new_queue}

      if state.queue_impl.length(state.operations_queue) == 0 do
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
    committed_queue =
      with {:value, _completed_operation, committed_queue} <-
             remove_completed_operation(state.queue_impl, state.operations_queue),
           {:value, next_operation, _not_committed_queue} <-
             get_next_operation(state.queue_impl, committed_queue) do
        GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), next_operation})
        committed_queue
      else
        {:empty, committed_queue} ->
          committed_queue
      end

    new_state = %{state | operations_queue: committed_queue}

    {:noreply, new_state}
  end

  defp remove_completed_operation(queue_impl, operations_queue) do
    dequeue(queue_impl, operations_queue)
  end

  def get_next_operation(queue_impl, operations_queue) do
    dequeue(queue_impl, operations_queue)
  end

  defp dequeue(queue_impl, queue) do
    case queue_impl.dequeue(queue) do
      {:value, operation, new_queue} -> {:value, operation, new_queue}
      {:empty, queue} -> {:empty, queue}
    end
  end
end
