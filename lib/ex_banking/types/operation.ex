defmodule ExBanking.Types.Operation do
  use TypedStruct

  alias ExBanking.Types.{Transaction, Actions}

  @type action() :: Actions.GetBalance.t()

  typedstruct do
    field(:action, action(), enfource: false)
    field(:transaction, Transaction.t(), enfource: false)
    field(:waiting_client, pid(), enforce: true)
  end
end
