# Example: Deploying unikernels using Albatross on NixOS

A very simple server is defined in [configuration.nix](./configuration.nix). It imports the module exposed by Albatross and enable it.
The Albatross package and module are imported in [flake.nix](./flake.nix).

The TLS endpoint is enabled and ports `8080` and `4433` are forwarded to the unikernels.

The TLS endpoint accepts commands from the internet to deploy or kill unikernels.
It needs `server.pem` and `server.key` to authenticate to clients and `cacert.pem` to authenticate clients. The client needs `ca_key.key` and `cacert.pem`.
Examples of public and private keys are already present in the repository, you can generate new keys using:

```sh
nix shell github:Julow/albatross -c albatross-client generate ca_key ca_db
```

Build a VM running the example configuration:

```sh
nixos-rebuild build-vm --flake ".#test"
```

And run it:

```sh
QEMU_NET_OPTS="hostfwd=tcp::1025-:1025,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::4433-:4433" QEMU_OPTS="-display none" ./result/bin/run-nixos-vm
```

Albatross should be running and can be controled on port `1025` using `albatross-client-bistro`.

Download the latest version of `https.hvt` from https://builds.robur.coop/job/static-website and deploy it:

```sh
curl -LO https://builds.robur.coop/job/static-website/build/latest/f/bin/https.hvt
```

```sh
nix shell github:Julow/albatross -c albatross-client create --force \
  --ca=./cacert.pem --ca-key=./ca_key.key --server-ca=./cacert.pem \
  --net=service --arg="--ipv4-gateway=10.0.0.1" \
  --arg="--ipv4=10.0.0.2/24" \
  https ./https.hvt
```

The `--ca`, `--ca-key` and `--server-ca` arguments specify the keys,
`--net=service --arg="--ipv4-gateway=..."` allows the unikernel to access the internal network
and `--arg="--ipv4=..."` assign a local IP address to the unikernel.

You should see:

```
host [vm: :https]: success: created VM
```

The logs can be viewed with:

```sh
nix shell github:Julow/albatross -c albatross-client console https \
  --ca=./cacert.pem --ca-key=./ca_key.key --server-ca=./cacert.pem
```

The http server should be accessible from the host system:

```sh
curl -k https://localhost:4433
```
