defmodule ExBanking do
  @moduledoc """
    Banking API
  """

  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) do
    with true <- String.valid?(user),
         true <- String.length(user) > 0 do
      case ExBanking.UserServerSupervisor.add_user_server(user) do
        {:ok, _user_server_pid} -> :ok
        {:error, {:already_started, _}} -> {:error, :user_already_exists}
      end
    else
      false -> {:error, :wrong_arguments}
    end
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}

  def deposit(user, amount, currency) do
    # validate params
    # check user exists
    # req to UserServer

    {:ok, 1000}
  end
end
