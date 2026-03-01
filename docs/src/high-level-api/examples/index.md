# [Examples](@id high-level-examples)

## How to run the examples at home

If you have your own XMPP server, you could configure the examples to use an account
there.

Alternatively, we describe below how to setup prosody in a docker-compose file,
and using [`go-sendxmpp`](https://salsa.debian.org/mdosch/go-sendxmpp) to
listen on the other side.

The compose file is available in the `script` directory of the main repository.
Before running it, create a directory `data` under `script`:

```bash
mkdir data
```

Then, run prosody:

```bash
docker-compose up
```

Finally, in another terminal in the same folder, create two test users.

```bash
sudo docker compose exec prosody prosodyctl register pinocchio localhost plopiplop
sudo docker compose exec prosody prosodyctl register gepetto localhost plopiplop
```

## Contents

```@contents
Pages = ["basic.md", "bot.md", "roster.md"]
```
