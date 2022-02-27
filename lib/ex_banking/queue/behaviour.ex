defmodule ExBanking.Queue.Behaviour do
  @moduledoc """
    API for queue
  """

  @type queue :: :queue.queue()


  @callback new() :: queue()

  @callback enqueue(any(), queue()) :: queue()

  @callback dequeue(queue()) :: {:value, any(), queue()} | {:empty, queue()}

  @callback length(queue()) :: non_neg_integer()
end
