defmodule ExBanking.Queue.Impl.ErlQueue do
  @behaviour ExBanking.Queue.Behaviour

  @impl true
  @spec enqueue(any(), :queue.queue()) :: :queue.queue()
  def enqueue(element, queue), do: :queue.in(element, queue)

  @impl true
  @spec dequeue(:queue.queue(any)) ::
          {:empty, :queue.queue()} | {:value, any, :queue.queue()}
  def dequeue(queue) do
    case :queue.out(queue) do
      {{:value, element}, queue} -> {:value, element, queue}
      {:empty, queue} -> {:empty, queue}
    end
  end

  @impl true
  @spec length(:queue.queue()) :: non_neg_integer()
  def length(queue), do: :queue.len(queue)

  @impl true
  @spec new :: :queue.queue()
  def new, do: :queue.new()
end
