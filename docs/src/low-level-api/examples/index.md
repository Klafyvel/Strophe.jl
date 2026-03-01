# [Examples](@id low-level-examples)

These examples are direct translation of [the examples provided by the underlying libstrophe library](https://github.com/strophe/libstrophe/blob/master/examples).

## How to Run the Examples at Home

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
docker compose -f scripts/docker-compose.yml up
```

Finally, in another terminal in the same folder, create two test users.

```bash
docker compose -f scripts/docker-compose.yml exec prosody prosodyctl register pinocchio localhost plopiplop
docker compose -f scripts/docker-compose.yml exec prosody prosodyctl register gepetto localhost plopiplop
```

## Contents

```@contents
Pages = ["01_basic.md", "02_roster.md", "03_bot.md"]
```
