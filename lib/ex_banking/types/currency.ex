defmodule ExBanking.Types.Currency do
  use TypedStruct

  typedstruct enforce: true do
    field(:name, String.t())
  end
end
