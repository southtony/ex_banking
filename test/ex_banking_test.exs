defmodule ExBankingTest do
  use ExUnit.Case, async: false

  alias ExBanking.Core

  setup do
    [user: UUID.uuid1()]
  end

  describe "create_user/1" do
    test "new user", %{user: user} do
      create_user_response = ExBanking.create_user(user)

      assert :user_exists = Core.User.user_exists(user)
      assert create_user_response == :ok
    end

    test "when user already exists", %{user: user} do
      ExBanking.create_user(user)
      assert {:error, :user_already_exists} = ExBanking.create_user(user)
    end

    test "when wrong username" do
      assert {:error, :wrong_arguments} = ExBanking.create_user(:john)
    end

    test "when empty username" do
      assert {:error, :wrong_arguments} = ExBanking.create_user("")
    end
  end

  describe "deposit/3" do
    test "make a deposit", %{user: user} do
      ExBanking.create_user(user)
      assert {:ok, 7000.00} = ExBanking.deposit(user, 7000, "usd")
    end

    test "when wrong arguments", %{user: user} do
      ExBanking.create_user(user)
      assert {:error, :wrong_arguments} = ExBanking.deposit(user, 0, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit(user, -8, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit(user, "kek", "usd")
    end

    test "user doesn't exists" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("John", 10, "usd")
    end
  end

  describe "withdraw/3" do
    test "make a withdraw", %{user: user} do
      ExBanking.create_user(user)

      ExBanking.deposit(user, 7000, "usd")
      ExBanking.deposit(user, 1000, "eur")

      assert {:ok, 6500.00} = ExBanking.withdraw(user, 500, "usd")
    end

    test "when not enough moeny", %{user: user} do
      ExBanking.create_user(user)

      ExBanking.deposit(user, 7000, "usd")
      assert {:error, :not_enough_money} = ExBanking.withdraw(user, 10000, "usd")
    end

    test "user doesn't exists" do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("John", 10, "usd")
    end
  end

  describe "get_balance/2" do
    test "get balance", %{user: user} do
      ExBanking.create_user(user)

      ExBanking.deposit(user, 7000, "usd")
      ExBanking.deposit(user, 1000, "eur")

      assert {:ok, 1000.00} = ExBanking.get_balance(user, "eur")
      assert {:ok, 7000.00} = ExBanking.get_balance(user, "usd")
    end

    test "user doesn't exists", %{user: user} do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance(user, "usd")
    end

    test "when wrong arguments", %{user: user} do
      ExBanking.create_user(user)
      assert {:error, :wrong_arguments} = ExBanking.get_balance(user, 5)
    end
  end

  describe "send/4" do
    test "send money", %{user: user} do
      ExBanking.create_user(user)

      another_user = UUID.uuid1()
      ExBanking.create_user(another_user)

      ExBanking.deposit(user, 1000, "usd")
      ExBanking.deposit(another_user, 300, "usd")

      assert {:ok, 500.00, 800.00} = ExBanking.send(user, another_user, 500, "usd")
    end

    test "when sender doesn't have enough money", %{user: user} do
      ExBanking.create_user(user)

      another_user = UUID.uuid1()
      ExBanking.create_user(another_user)

      ExBanking.deposit(user, 10, "usd")

      assert {:error, :not_enough_money} = ExBanking.send(user, another_user, 500, "usd")
    end

    test "when sender doesn't exists", %{user: user} do
      ExBanking.create_user(user)
      another_user = UUID.uuid1()
      assert {:error, :sender_does_not_exist} == ExBanking.send(another_user, user, 12, "usd")
    end

    test "when receiver doesn't exists", %{user: user} do
      ExBanking.create_user(user)

      another_user = UUID.uuid1()
      assert {:error, :receiver_does_not_exist} == ExBanking.send(user, another_user, 12, "usd")
    end
  end

  describe "complex balance operations per one user" do
    test "a few deposit transactions", %{user: user} do
      ExBanking.create_user(user)

      ExBanking.deposit(user, 7000, "usd")
      ExBanking.deposit(user, 2500, "usd")
      ExBanking.deposit(user, 100, "usd")

      {:ok, new_balance} = ExBanking.deposit(user, 400, "usd")

      assert new_balance == 10000.00
    end
  end
end
