# Cloud Init Usage

> The current cloud-init is tailored towards Ubuntu

## Testing cloud-init locally for free

### 1. Install Multipass

Multipass is able to provide Ubuntu VMs that can be initialized with cloud-init to simulate cloud deployments locally. It is available for Linux, Windows and MacOS.

Additional resources:
- https://multipass.run/install
- https://multipass.run/docs/tutorial

### 2. Run

```bash
multipass launch -n dusknode --cloud-init dusknode.yaml
```

This will create a VM with the latest Ubuntu LTS image and apply the `dusknode.yml` cloud-init configuration.

This will create a user "dusk" along with some other configuation and the execution of the `node-installer.sh` script. Ensure your SSH public key is added to the ssh_authorized_keys field in the YAML configuration before applying it.

### 3. Use

#### Check out existing VMs
```bash
multipass list
```

#### Open shell of dusknode VM
```bash 
multipass shell dusknode
```

You can either use the Multipass GUI or use the CLI. Running `sudo su dusk` in the respective VM, will log you in as the dusk user who has the node installed.

#### Restart multipass on linux

```bash
sudo snap restart multipass.multipassd
```
