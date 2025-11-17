# Kubernetes on Hetzner

Installing a Kubernetes cluster on Hetzner with [Kube Hetzner](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner).

[Kube Hetzner installation](https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner?tab=readme-ov-file#-do-not-skip-creating-your-kubetf-file-and-the-opensuse-microos-snapshot)

If you are in a temp environment like a VM you might want to create a SSH key

```bash
ssh-keygen -t ed25519
```

Build the images for the Hetzner VMs:

```bash
export HCLOUD_TOKEN="your_hcloud_token"
packer init hcloud-microos-snapshots.pkr.hcl
packer build hcloud-microos-snapshots.pkr.hcl
hcloud context create agentic-k8s
```

Provision the cluster:

```bash
export TF_VAR_hcloud_token="your_hcloud_token"
terraform init --upgrade
terraform validate
terraform apply -auto-approve
```
