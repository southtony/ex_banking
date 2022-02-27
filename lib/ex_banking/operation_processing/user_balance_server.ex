defmodule ExBanking.OperationProcessing.UserBalanceServer do
  use GenServer

  alias ExBanking.Types.{
    Operation,
    Transaction,
    Actions
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:state], name: opts[:server_name])
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast(
        {:exec_operation, %Operation{transaction: %Transaction{operation_type: :increase}} = op},
        state
      ) do
    transaction = op.transaction
    current_amount = state[transaction.currency] || 0

    new_amount = Decimal.add(current_amount, transaction.amount)

    new_state = Map.put(state, transaction.currency, new_amount)

    send(op.waiting_client, {:ok, Decimal.to_float(new_amount)})

    {:noreply, new_state}
  end

  @impl true
  def handle_cast(
        {:exec_operation, %Operation{transaction: %Transaction{operation_type: :decrease}} = op},
        state
      ) do
    transaction = op.transaction
    current_amount = state[transaction.currency] || 0

    new_amount = Decimal.sub(current_amount, transaction.amount)

    if Decimal.negative?(new_amount) do
      send(op.waiting_client, {:error, :not_enough_money})
      {:noreply, state}
    else
      send(op.waiting_client, {:ok, Decimal.to_float(new_amount)})
      new_state = Map.put(state, transaction.currency, new_amount)
      {:noreply, new_state}
    end
  end

  def handle_cast(
        {:exec_operation, %Operation{action: %Actions.GetBalance{currency: currency}} = op},
        state
      ) do
    amount = state[currency] || Decimal.new(0)
    send(op.waiting_client, {:ok, Decimal.to_float(amount)})
    {:noreply, state}
  end
end
