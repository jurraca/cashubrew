Mix.install([{:req, "~> 0.5.6"}])

defmodule RunClients do

  def read_tokens(path) do
    path
    |> File.read!
    |> Jason.decode!
  end

  def run(token_path) do
     tokens = read_tokens(token_path)
     Task.async_stream(tokens, fn tk ->
       resp = Req.post!("http://localhost:4000/api/v1/swap", json: tk)
       dbg(resp.body)
       end, ordered: false)
     |> Stream.run()
  end
end

RunClients.run("tokens.json")
