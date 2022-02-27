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
    committed_queue =
      with {{:value, _completed_operation}, committed_queue} <-
             remove_completed_operation(state.operations_queue),
           {{:value, next_operation}, _not_committed_queue} <- get_next_operation(committed_queue) do
        GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), next_operation})
        committed_queue
      else
        {:empty, committed_queue} ->
          committed_queue
      end

    new_state = %{state | operations_queue: committed_queue}

    {:noreply, new_state}
  end

  defp remove_completed_operation(operations_queue) do
    dequeue(operations_queue)
  end

  def get_next_operation(operations_queue) do
    dequeue(operations_queue)
  end

  defp dequeue(queue) do
    case :queue.out(queue) do
      {{:value, operation}, new_queue} -> {{:value, operation}, new_queue}
      {:empty, queue} -> {:empty, queue}
    end
  end
end
