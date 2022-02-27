defmodule ExBanking do
  @moduledoc """
    Banking API
  """

  alias ExBanking.Core.{Validator, User}

  alias ExBanking.Types.{
    Operation,
    Transaction,
    Actions
  }

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user),
         :user_does_not_exist <- User.user_exists(user) do
      case ExBanking.ServersManagerSupervisor.add_user(user) do
        :ok -> :ok
        other -> raise "Something went wrong. Message: #{inspect(other)}"
      end
    else
      {:error, :user_not_valid} -> {:error, :wrong_arguments}
      :user_exists -> {:error, :user_already_exists}
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def deposit(user, amount, currency) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user),
         :user_exists <- ExBanking.Core.User.user_exists(user),
         {:ok, :amount_is_valid} <- Validator.validate_amount(amount),
         {:ok, :currency_is_valid} <- Validator.validate_currency(currency),
         {:ok, converted_amount} <- ExBanking.Core.DecimalConverter.convert_with_round(amount) do
      transaction = %Transaction{
        amount: converted_amount,
        currency: currency,
        operation_type: :increase
      }

      operation = %Operation{
        transaction: transaction,
        waiting_client: self()
      }

      case ExBanking.API.UserBalance.execute(user, operation) do
        {:ok, user_balance} ->
          {:ok, user_balance}

        {:error, :operation_state_full} ->
          {:error, :too_many_requests_to_user}
      end
    else
      :user_does_not_exist -> {:error, :user_does_not_exist}
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
         :user_exists <- ExBanking.Core.User.user_exists(user),
         {:ok, :amount_is_valid} <- Validator.validate_amount(amount),
         {:ok, :currency_is_valid} <- Validator.validate_currency(currency),
         {:ok, converted_amount} <- ExBanking.Core.DecimalConverter.convert_with_round(amount) do
      transaction = %Transaction{
        amount: converted_amount,
        currency: currency,
        operation_type: :decrease
      }

      operation = %Operation{
        transaction: transaction,
        waiting_client: self()
      }

      case ExBanking.API.UserBalance.execute(user, operation) do
        {:ok, user_balance} -> {:ok, user_balance}
        {:error, :operation_state_full} -> {:error, :too_many_requests_to_user}
        {:error, :not_enough_money} -> {:error, :not_enough_money}
      end
    else
      :user_does_not_exist -> {:error, :user_does_not_exist}
      {:error, _} -> {:error, :wrong_arguments}
    end
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def get_balance(user, currency) do
    with {:ok, :user_is_valid} <- Validator.validate_user(user),
         :user_exists <- ExBanking.Core.User.user_exists(user),
         {:ok, :currency_is_valid} <- Validator.validate_currency(currency) do
      operation = %Operation{
        action: %Actions.GetBalance{currency: currency},
        waiting_client: self()
      }

      case ExBanking.API.UserBalance.execute(user, operation) do
        {:ok, user_balance} -> {:ok, user_balance}
        {:error, :operation_state_full} -> {:error, :too_many_requests_to_user}
      end
    else
      :user_does_not_exist -> {:error, :user_does_not_exist}
      {:error, _} -> {:error, :wrong_arguments}
    end
  end

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}

  def send(from_user, to_user, amount, currency) do
    with {:user_exists, :sender} <- {ExBanking.Core.User.user_exists(from_user), :sender},
         {:user_exists, :receiver} <- {ExBanking.Core.User.user_exists(to_user), :receiver} do
      with {{:ok, from_user_balance}, :sender} <-
             {ExBanking.withdraw(from_user, amount, currency), :sender},
           {{:ok, to_user_balance}, :receiver} <-
             {ExBanking.deposit(to_user, amount, currency), :receiver} do
        {:ok, from_user_balance, to_user_balance}
      else
        {{:error, :too_many_requests_to_user}, :sender} ->
          {:error, :too_many_requests_to_sender}

        {{:error, :too_many_requests_to_user}, :receiver} ->
          {:error, :too_many_requests_to_receiver}

        {{:error, :not_enough_money}, _} ->
          {:error, :not_enough_money}

        error ->
          error
      end
    else
      {:user_does_not_exist, :sender} -> {:error, :sender_does_not_exist}
      {:user_does_not_exist, :receiver} -> {:error, :receiver_does_not_exist}
    end
  end
end
