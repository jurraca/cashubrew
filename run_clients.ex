Mix.install([{:req, "~> 0.5.6"}])

defmodule RunClients do

  def read_tokens(path) do
    path
    |> File.read!
    |> Jason.decode!
  end

  def swap(tokens) do
     Enum.map(tokens, fn tk -> Req.post("http://localhost:4000/api/v1/swap", body: tk) end)
  end

  def run(tokens) do
     Task.async_stream(fn -> swap(tokens) end, ordered: false)
     |> Stream.run()
  end
end
