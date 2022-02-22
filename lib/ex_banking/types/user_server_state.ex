defmodule ExBanking.Types.UserServerState do
  @moduledoc """
    A struct representing a UserServerState
  """

  use TypedStruct

  alias ExBanking.Types.{Transaction, BalanceOperation}

  typedstruct do
    field(:transactions, [Transaction.t()])
    field(:pending_operations, :queue.queue(BalanceOperation.t()))
  end
end
