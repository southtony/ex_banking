defmodule ExBanking do
  @moduledoc """
    Banking API
  """

  alias ExBanking.Core.Validator

  alias ExBanking.Types.{
    BalanceOperation,
    Transaction,
    Currency
  }

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user) do
      case ExBanking.UserServerSupervisor.add_user_server(user) do
        {:ok, _user_server_pid} -> :ok
        {:error, {:already_started, _}} -> {:error, :user_already_exists}
        other -> IO.inspect(other)
      end
    else
      {:error, :user_not_valid} -> {:error, :wrong_arguments}
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def deposit(user, amount, currency) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user),
         {:ok, :amount_is_valid} <- Validator.validate_amount(amount),
         {:ok, :currency_is_valid} <- Validator.validate_currency(currency),
         {:ok, converted_amount} <- ExBanking.Core.DecimalConverter.convert_with_round(amount),
         {:ok, user_server} <- ExBanking.Core.User.get_pid_user_server(user) do
      transaction = %Transaction{
        amount: converted_amount,
        currency: %Currency{name: currency},
        operation_type: :increase
      }

      operation = %BalanceOperation{
        transaction: transaction,
        action: :increase
      }

      case ExBanking.OperationProcessing.UserServer.execute(user_server, operation) do
        {:ok, user_balance} -> {:ok, user_balance}
        {:error, :operation_state_full} -> {:error, :too_many_requests_to_user}
      end
    else
      {:error, :user_server_not_found} -> {:error, :user_does_not_exist}
      {:error, _} -> {:error, :wrong_arguments}
    end
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}

  def withdraw(user, amount, currency) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user),
         {:ok, :amount_is_valid} <- Validator.validate_amount(amount),
         {:ok, :currency_is_valid} <- Validator.validate_currency(currency),
         {:ok, converted_amount} <- ExBanking.Core.DecimalConverter.convert_with_round(amount),
         {:ok, user_server} <- ExBanking.Core.User.get_pid_user_server(user) do
      transaction = %Transaction{
        amount: converted_amount,
        currency: %Currency{name: currency},
        operation_type: :decrease
      }

      operation = %BalanceOperation{
        transaction: transaction,
        action: :decrease
      }

      case ExBanking.OperationProcessing.UserServer.execute(user_server, operation) do
        {:ok, user_balance} -> {:ok, user_balance}
        {:error, :operation_state_full} -> {:error, :too_many_requests_to_user}
        {:error, :not_enough_money} -> {:error, :not_enough_money}
      end
    else
      {:error, :user_server_not_found} -> {:error, :user_does_not_exist}
      {:error, _} -> {:error, :wrong_arguments}
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def get_balance(user, currency) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user),
         {:ok, :currency_is_valid} <- Validator.validate_currency(currency),
         {:ok, user_server} <- ExBanking.Core.User.get_pid_user_server(user) do
      operation = %BalanceOperation{
        action: :get_balance,
        currency: %Currency{name: currency}
      }

      case ExBanking.OperationProcessing.UserServer.execute(user_server, operation) do
        {:ok, user_balance} -> {:ok, user_balance}
        {:error, :operation_state_full} -> {:error, :too_many_requests_to_user}
      end
    else
      {:error, :user_server_not_found} -> {:error, :user_does_not_exist}
      {:error, _} -> {:error, :wrong_arguments}
    end
  end
end
