# Voyager Labs Task

## Repository Structure
To help you find what you need, here is the repository structure:
```bash
.
├── ansible/
│   └── playbook.yaml               # Playbook required by task
│   └── kubernetes.yaml             # Playbook to install k8s and deploy apache
│
├── keys/                           # Directory where the ssh keys be created
│
├── kubernetes/
│   └── apache-manifest.yaml        # Manifest file for apache
│
├── python/
│   └── app.py                      # Python script to create EBS snapshots
│
└── terraform/
    └── main.tf                     # Terraform code to deploy ec2 instances
```

## Key Points
- Ansible ssh keys create with terraform
- inventory.ini file created with terraform
- Kubernetes and apache deployed with ansible