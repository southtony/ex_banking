defmodule ExBanking.OperationProcessing.PendingOperationsServer do
  use GenServer

  alias ExBanking.Types.{
    Operation,
    ServerStates.PendingOperationsServerState
  }

  @type server_name :: {:via, module(), term()}
  @type on_start :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}

  @spec start_link(server_name: server_name(), state: PendingOperationsServerState.t()) ::
          on_start()
  def start_link(server_name: server_name, state: %PendingOperationsServerState{} = state) do
    GenServer.start_link(__MODULE__, state, name: server_name)
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_call({:add, %Operation{} = op}, _from, %PendingOperationsServerState{} = state) do
    if state.queue_impl.length(state.operations_queue) < state.operations_limit do
      new_queue = state.queue_impl.enqueue(op, state.operations_queue)

      if !state.task_in_progress_exists? do
        case state.queue_impl.dequeue(state.operations_queue) do
          {:value, operation, _} ->
            GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), operation})
            new_state = %{state | operations_queue: new_queue, task_in_progress_exists?: true}
            {:reply, :ok, new_state}

          {:empty, _} ->
            GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), op})
            new_state = %{state | operations_queue: new_queue, task_in_progress_exists?: true}
            {:reply, :ok, new_state}
        end
      else
        new_state = %{state | operations_queue: new_queue}
        {:reply, :ok, new_state}
      end
    else
      send(op.waiting_client, {:error, :operation_state_full})
      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_cast(:ack, %PendingOperationsServerState{} = state) do
    {:value, _completed_operation, new_queue} = state.queue_impl.dequeue(state.operations_queue)

    task_in_progress_exists? =
      case state.queue_impl.dequeue(new_queue) do
        {:value, operation, _new_queue} ->
          GenServer.cast(state.user_balance_server_name, {:exec_operation, self(), operation})
          true

        _ ->
          false
      end

    new_state = %{
      state
      | operations_queue: new_queue,
        task_in_progress_exists?: task_in_progress_exists?
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:EXIT, _from, _reason}, state) do
    {:noreply, state}
  end
end
