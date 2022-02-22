defmodule ExBanking.Types.BalanceOperation do
  use TypedStruct

  alias ExBanking.Types.{Transaction, Currency}

  @type action() :: :increase | :decrease | :get_balance

  typedstruct do
    field(:action, action(), enfource: true)
    field(:transaction, Transaction.t())
    field(:currency, Currency.t())
  end
end
