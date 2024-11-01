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
- The playbooks can run with terraform
- Terraform checks ec2 instances can accept ssh connections.

## How to Run everything

To set up your environment, please follow these steps. Ensure your AWS configuration is set up, and have Ansible and Terraform installed and configured on your local machine before proceeding.

1. **Initialize Terraform**:
   This command initializes the Terraform configuration.
   ```bash
   terraform init
   ```

2. **Apply the Terraform configuration**:
   This command will create the EC2 instances and necessary resources.
   ```bash
   terraform apply
   ```

3. **Run the Ansible playbook required by the task**:
   After the EC2 instances are up, run the following command to execute the Ansible playbook.
   ```bash
   ansible-playbook -i inventory.ini --private-key ./../keys/voyager-key.pem playbook.yaml
   ```

4. **Run the Kubernetes setup playbook**:
   To install Kubernetes and deploy Apache, use the following command:
   ```bash
   ansible-playbook -i inventory.ini --private-key ./../keys/voyager-key.pem kubernetes.yaml
   ```

5. **Run the Python application to take snapshots**:
    To run the Python application for taking snapshots, use the following command:
    ```bash
    python app.py
    ```
