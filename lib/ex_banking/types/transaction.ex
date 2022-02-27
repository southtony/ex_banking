defmodule ExBanking.Types.Transaction do
  use TypedStruct

  @type operation_type :: :increase | :decrease

  typedstruct enforce: true do
    field(:currency, String.t())
    field(:amount, number())
    field(:operation_type, operation_type())
  end
end
