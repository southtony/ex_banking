defmodule ExBankingTest do
  use ExUnit.Case, async: true

  alias ExBanking.Core

  setup do
    on_exit(fn ->
      ExBanking.UserServerSupervisor
      |> DynamicSupervisor.which_children()
      |> Enum.each(fn {_, pid, _, _} ->
        DynamicSupervisor.terminate_child(ExBanking.UserServerSupervisor, pid)
      end)
    end)

    :ok
  end

  describe "create_user/1" do
    test "new user" do
      create_user_response = ExBanking.create_user("John")

      assert {:ok, _user_server_pid} = Core.User.get_pid_user_server("John")

      {:ok, user_server_pid} = Core.User.get_pid_user_server("John")

      assert Process.alive?(user_server_pid)

      assert create_user_response == :ok
    end

    test "when user already exists" do
      ExBanking.create_user("John")
      assert {:error, :user_already_exists} = ExBanking.create_user("John")
    end

    test "when wrong username" do
      assert {:error, :wrong_arguments} = ExBanking.create_user(:john)
    end

    test "when empty username" do
      assert {:error, :wrong_arguments} = ExBanking.create_user("")
    end
  end

  describe "deposit/3" do
    test "make a deposit" do
      ExBanking.create_user("John")
      assert {:ok, 7000.00} = ExBanking.deposit("John", 7000, "usd")
    end

    test "when wrong arguments" do
      ExBanking.create_user("John")
      assert {:error, :wrong_arguments} = ExBanking.deposit("John", 0, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit("John", -8, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit("John", "kek", "usd")
    end

    test "user doesn't exists" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("John", 10, "usd")
    end
  end

  describe "withdraw/3" do
    test "make a withdraw" do
      ExBanking.create_user("John")

      ExBanking.deposit("John", 7000, "usd")
      ExBanking.deposit("John", 1000, "eur")

      assert {:ok, 6500.00} = ExBanking.withdraw("John", 500, "usd")
    end

    test "when not enough moeny" do
      ExBanking.create_user("John")

      ExBanking.deposit("John", 7000, "usd")
      assert {:error, :not_enough_money} = ExBanking.withdraw("John", 10000, "usd")
    end

    test "user doesn't exists" do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("John", 10, "usd")
    end
  end

  describe "get_balance/2" do
    test "get balance" do
      ExBanking.create_user("John")

      ExBanking.deposit("John", 7000, "usd")
      ExBanking.deposit("John", 1000, "eur")

      assert {:ok, 1000.00} = ExBanking.get_balance("John", "eur")
      assert {:ok, 7000.00} = ExBanking.get_balance("John", "usd")
    end

    test "user doesn't exists" do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("John", "usd")
    end

    test "when wrong arguments" do
      ExBanking.create_user("John")
      assert {:error, :wrong_arguments} = ExBanking.get_balance("John", 5)
    end
  end

  describe "complex balance operations per one user" do
    test "a few deposit transactions" do
      ExBanking.create_user("John")

      ExBanking.deposit("John", 7000, "usd")
      ExBanking.deposit("John", 2500, "usd")
      ExBanking.deposit("John", 100, "usd")

      {:ok, new_balance} = ExBanking.deposit("John", 400, "usd")

      assert new_balance == 10000.00
    end
  end
end
