defmodule ExBanking.Types.Transaction do
  use TypedStruct

  alias ExBanking.Types.Currency

  @type operation_type :: :increase | :decrease

  typedstruct enforce: true do
    field(:currency, Currency.t())
    field(:amount, number())
    field(:operation_type, operation_type())
  end
end
