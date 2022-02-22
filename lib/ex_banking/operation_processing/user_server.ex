defmodule ExBanking.OperationProcessing.UserServer do
  use GenServer

  alias ExBanking.Types.{BalanceOperation, UserServerState}

  def start_link(server_name: server_name) do
    state = %UserServerState{
      transactions: [],
      pending_operations: :queue.new()
    }

    GenServer.start_link(__MODULE__, state, name: server_name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def execute(user_server, %BalanceOperation{action: :increase} = op) do
    GenServer.call(user_server, {:exec_operation, op})
  end

  def execute(user_server, %BalanceOperation{action: :decrease} = op) do
    GenServer.call(user_server, {:exec_operation, op})
  end

  def execute(user_server, %BalanceOperation{action: :get_balance} = op) do
    GenServer.call(user_server, {:exec_operation, op})
  end

  @impl true
  def handle_call({:enqueue_operation, op}, _from, state) do
    if :queue.len(state.pending_operations) < 10 do
      new_state = %{state | pending_operations: :queue.in(op, state.pending_operations)}
      {:reply, :ok, new_state}
    else
      {:reply, {:error, :pending_state_operations_full}, state}
    end
  end

  def handle_call({:exec_operation, %BalanceOperation{action: :increase} = op}, _from, state) do
    user_transactions = [op.transaction | state.transactions]
    new_state = %{state | transactions: user_transactions}

    currency = op.transaction.currency

    amount = calculate_balance(new_state.transactions, currency)

    {:reply, {:ok, Decimal.to_float(amount)}, new_state}
  end

  def handle_call({:exec_operation, %BalanceOperation{action: :decrease} = op}, _from, state) do
    user_transactions = [op.transaction | state.transactions]
    new_state = %{state | transactions: user_transactions}

    currency = op.transaction.currency

    amount = calculate_balance(new_state.transactions, currency)

    response =
      if Decimal.negative?(amount) do
        {:error, :not_enough_money}
      else
        {:ok, Decimal.to_float(amount)}
      end

    {:reply, response, new_state}
  end

  def handle_call({:exec_operation, %BalanceOperation{action: :get_balance} = op}, _from, state) do
    {:reply, {:ok, Decimal.to_float(calculate_balance(state.transactions, op.currency))}, state}
  end

  defp calculate_balance(transactions, currency) do
    transactions = Enum.reverse(transactions)

    Enum.reduce(transactions, 0, fn tr, acc ->
      if tr.currency == currency do
        case tr.operation_type do
          :increase -> Decimal.add(tr.amount, acc)
          :decrease -> Decimal.sub(acc, tr.amount)
        end
      else
        acc
      end
    end)
  end
end
