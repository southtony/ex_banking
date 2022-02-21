defmodule ExBanking.Types.BalanceOperation do
  use TypedStruct

  alias ExBanking.Types.Transaction

  @type action() :: :increase | :decrease | :get_balance

  typedstruct do
    field(:action, action(), enfource: true)
    field(:transaction, Transaction.t())
  end
end
