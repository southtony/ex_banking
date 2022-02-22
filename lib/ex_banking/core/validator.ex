defmodule ExBanking.Core.Validator do
  def validate_user(user) do
    if is_valid_non_empty_string?(user) do
      {:ok, :user_is_valid}
    else
      {:error, :user_not_valid}
    end
  end

  def validate_amount(amount) do
    if is_number(amount) && amount > 0 do
      {:ok, :amount_is_valid}
    else
      {:error, :amount_not_valid}
    end
  end

  def validate_currency(currency) do
    if is_valid_non_empty_string?(currency) do
      {:ok, :currency_is_valid}
    else
      {:error, :currency_not_valid}
    end
  end

  defp is_valid_non_empty_string?(string) do
    String.valid?(string) && String.length(string) > 0
  end
end
