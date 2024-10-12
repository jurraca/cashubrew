defmodule Mix.Tasks.GenerateInputs do
  use Mix.Task

  alias Cashubrew.Crypto.BDHKE
  alias Cashubrew.Mint

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    [keyset] = Mint.get_keysets()

    repo = Application.get_env(:cashubrew, :repo)
    a = Mint.get_key_for_amount(repo, keyset.id, 1)

    {r, _r_pub} = BDHKE.generate_keypair(<<1::256>>)
    {r_new, _r_pub} = BDHKE.generate_keypair(<<1::256>>)

    {x, c} = get_proof(a.private_key, a.public_key, "secret", r)
    b_prime = get_blinded_message("secret", r_new)

    input = Cashubrew.Cashu.Proof.new(1, keyset.id, x, Base.encode16(c, case: :lower))

    output =
      Cashubrew.Cashu.BlindedMessage.new_blinded_message(
        1,
        keyset.id,
        Base.encode16(b_prime, case: :lower)
      )

    Jason.encode!(%{inputs: [input], outputs: [output]}) |> IO.puts()
  end

  def get_proof(a, a_pub, x, r) do
    # STEP 1: Alice blinds the message
    {b_prime, _} = BDHKE.step1_alice(x, r)

    # STEP 2: Bob signs the blinded message
    {c_prime, _, _} = BDHKE.step2_bob(b_prime, a)

    # STEP 3: Alice unblinds the signature
    c = BDHKE.step3_alice(c_prime, r, a_pub)

    {x, c}
  end

  def get_blinded_message(x, r) do
    # STEP 1: Alice blinds the message
    {b_prime, _} = BDHKE.step1_alice(x, r)

    b_prime
  end
end
