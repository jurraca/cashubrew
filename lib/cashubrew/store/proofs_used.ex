defmodule Cashubrew.Store.ProofsUsed do
  use GenServer

  alias :mnesia, as: Mnesia
  alias Cashubrew.Cashu.Proof


  def add(%Proof{} = p) do
    GenServer.cast(__MODULE__, {:add, p})
  end

  def available?(secret) do
    GenServer.call(__MODULE__, {:available?, secret})
  end

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state), do: {:ok, state, {:continue, :start_mnesia}}

  defp create_schema do
    with :ok <- Mnesia.create_schema([node()]) do
      :ok
    else
      {:error,{_, {:already_exists, _}}} -> :ok
    end
  end

  defp create_table do
    with {:atomic, :ok} <- Mnesia.create_table(ProofsUsed, [attributes: [:amount, :id, :secret, :c, :created]]) do
      :ok
    else
      {:aborted, {:already_exists, ProofsUsed}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_index do
    with {:atomic, :ok} <- Mnesia.add_table_index(ProofsUsed, :secret) do
      :ok
    else
      {:aborted, {:already_exists, _, _}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  def handle_continue(:start_mnesia, state) do
    with :ok <- create_schema(),
      :ok <- Mnesia.start(),
      :ok <- create_table(),
      :ok <- create_index() do
        {:noreply, state}
    else
      {:error, reason} -> {:stop, reason, state}
    end
  end

  def handle_cast({:add, %Proof{} = p}, state) do
    with :ok <- Mnesia.dirty_write({ProofsUsed, p.amount, p.id, p.secret, p."C", DateTime.utc_now()}) do
      {:noreply, state}
    end
  end

  def handle_call({:available?, secret}, _from, state) do
    with {:atomic, [{ProofsUsed, _, _, ^secret, _, _}]} <- Mnesia.transaction(fn ->
      Mnesia.index_read(ProofsUsed, secret, :secret)
    end) do
      {:reply, :yes, state}
    else
      {:atomic, []} -> {:reply, :no, state}
      e -> {:reply, {:error, e}, state}
    end
  end

end
