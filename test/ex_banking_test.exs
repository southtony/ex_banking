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
end
