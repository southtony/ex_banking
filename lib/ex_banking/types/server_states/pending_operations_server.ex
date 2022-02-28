defmodule ExBanking.Types.ServerStates.PendingOperationsServerState do
  use TypedStruct

  alias ExBanking.Types.Operation

  @type server_name :: {:via, module(), term()}

  typedstruct enforce: true do
    field(:user_balance_server_name, server_name())
    field(:operations_queue, :queue.queue(Operation.t()))
    field(:queue_impl, module())
    field(:operations_limit, non_neg_integer())
    field(:task_in_progress_exists?, boolean())
  end
end
