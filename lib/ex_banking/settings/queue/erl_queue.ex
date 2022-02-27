defmodule ExBanking.Settings.Queue.ErlQueue do
  def impl(), do: Application.fetch_env!(:ex_banking, :queue_impl)
end
