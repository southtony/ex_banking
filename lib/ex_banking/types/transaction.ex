defmodule ExBanking.Types.Transaction do
  use TypedStruct

  alias ExBanking.Types.Currency

  typedstruct enforce: true do
    field(:currency, Currency.t())
    field(:amount, number())
  end
end
