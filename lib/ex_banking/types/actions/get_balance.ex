defmodule ExBanking.Types.Actions.GetBalance do
  use TypedStruct

  typedstruct enforce: true do
    field(:currency, String.t())
  end
end
