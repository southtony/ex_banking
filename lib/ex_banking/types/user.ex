defmodule ExBanking.Types.User do
  @moduledoc """
    A struct representing a user
  """

  use TypedStruct

  alias ExBanking.Types.{Transaction, BalanceOperation}

  typedstruct do
    field(:name, String.t(), enforce: true)
    field(:transactions, [Transaction.t()])
    field(:pending_operations, [BalanceOperation.t()])
  end
end
