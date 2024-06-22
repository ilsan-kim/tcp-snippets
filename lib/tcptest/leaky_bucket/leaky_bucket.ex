defmodule Tcptest.LeakyBucket do
  use GenServer

  @me __MODULE__

  # API
  def start_link(capacity) do
    GenServer.start_link(__MODULE__, capacity, name: @me)
  end

  def call(func) do
    case GenServer.call(@me, {:call, func}) do
      :ok -> IO.puts("Function executed immediately")
      :wait -> IO.puts("Function queued")
    end
  end

  defp schedule_drain() do
    Process.send_after(self(), :drain, 5000)
  end

  # IMPLEMENT
  def init(capacity) do
    schedule_drain()

    {:ok, %{queue: [], capacity: capacity, level: 0}}
  end

  def handle_info(:drain, state) do
    case state.queue do
      [func | rest] ->
        func.()
        schedule_drain()
        {:noreply, %{queue: rest, capacity: state.capacity, level: max(state.level - 1, 0)}}

      [] ->
        schedule_drain()
        {:noreply, %{queue: [], capacity: state.capacity, level: max(state.level - 1, 0)}}
    end
  end

  def handle_call({:call, func}, _from, state) do
    case state.level do
      l when l == state.capacity ->
        # state.queue 가 [] 일때랑, func 가 있을때 나눠서 처리
        q = state.queue ++ [func]
        {:reply, :wait, %{state | queue: q}}

      _ ->
        func.()
        {:reply, :ok, %{state | level: min(state.level + 1, state.capacity)}}
    end
  end
end
