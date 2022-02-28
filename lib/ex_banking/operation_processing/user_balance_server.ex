defmodule ExBanking.OperationProcessing.UserBalanceServer do
  use GenServer

  alias ExBanking.Types.{
    Operation,
    Transaction,
    Actions
  }

  @type server_name :: {:via, module(), term()}
  @type on_start :: {:ok, pid()} | :ignore | {:error, {:already_started, pid()} | term()}
  @type state :: %{(currency :: String.t()) => amount :: Decimal.t()}

  @spec start_link(server_name: server_name(), state: state()) :: on_start()
  def start_link(server_name: server_name, state: state) do
    GenServer.start_link(__MODULE__, state, name: server_name)
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    {:ok, state}
  end

  @impl true
  def handle_cast(
        {:exec_operation, from,
         %Operation{transaction: %Transaction{operation_type: :increase}} = op},
        state
      ) do
    transaction = op.transaction
    current_amount = state[transaction.currency] || 0

    new_amount = Decimal.add(current_amount, transaction.amount)

    new_state = Map.put(state, transaction.currency, new_amount)

    send(op.waiting_client, {:ok, Decimal.to_float(new_amount)})

    GenServer.cast(from, :ack)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        {:exec_operation, from,
         %Operation{transaction: %Transaction{operation_type: :decrease}} = op},
        state
      ) do
    transaction = op.transaction
    current_amount = state[transaction.currency] || 0

    new_amount = Decimal.sub(current_amount, transaction.amount)

    if Decimal.negative?(new_amount) do
      send(op.waiting_client, {:error, :not_enough_money})
      GenServer.cast(from, :ack)
      {:noreply, state}
    else
      send(op.waiting_client, {:ok, Decimal.to_float(new_amount)})
      new_state = Map.put(state, transaction.currency, new_amount)
      GenServer.cast(from, :ack)
      {:noreply, new_state}
    end
  end

  def handle_cast(
        {:exec_operation, from, %Operation{action: %Actions.GetBalance{currency: currency}} = op},
        state
      ) do
    amount = state[currency] || Decimal.new(0)
    send(op.waiting_client, {:ok, Decimal.to_float(amount)})
    GenServer.cast(from, :ack)
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _from, _reason}, state) do
    {:noreply, state}
  end
end
