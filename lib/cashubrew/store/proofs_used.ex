defmodule Cashubrew.Store.ProofsUsed do
  use GenServer

  alias :mnesia, as: Mnesia



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
    with {:atomic, :ok} <- Mnesia.create_table(ProofsUsed, [attributes: [:amount, :id, :secret, :C, :created]]) do
      :ok
    else
      {:aborted, {:already_exists, ProofsUsed}} -> :ok
      {:aborted, reason} -> {:error, reason}
    end
  end

  defp create_index do
    with :ok <- Mnesia.add_table_index(ProofsUsed, :secret) do
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

end
