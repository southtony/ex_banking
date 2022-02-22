defmodule ExBanking.Core.DecimalConverter do
  @precision 2

  @spec convert_with_round(number) :: {:ok, Decimal.t()}
  def convert_with_round(number) when is_integer(number) do
    amount =
      number
      |> Decimal.new()
      |> Decimal.round(@precision)

    {:ok, amount}
  end

  def convert_with_round(number) when is_float(number) do
    amount =
      number
      |> Decimal.from_float()
      |> Decimal.round(@precision)

    {:ok, amount}
  end
end
