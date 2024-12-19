# goryunov_build
Git: https://github.com/Goryounov/cloud-computing

Shell stages:
```shell
rm -f /home/ubuntu/jenkins/workspace/goryunov_build/*.gz
sudo docker compose build
```

```shell
docker save artstyle-artstyle-client:latest -o artstyle-client.tar
gzip artstyle-client.tar
docker save artstyle-artstyle-server:latest -o artstyle-server.tar
gzip artstyle-server.tar
```

Files for archiving:
```shell
*.tar.gz,.env,docker-compose.yml
```

# goryunov_infra
Git: https://github.com/Goryounov/artstyle-ci-cd

Shell stages:
```shell
#!/bin/bash
[ -f /home/ubuntu/openstack.rc ] && source /home/ubuntu/openstack.rc

set -a
[ -f /home/ubuntu/.env ] && source /home/ubuntu/.env
set +a

openstack stack create -t heat_template.yaml goryunov_infra_server \
--parameter image_id="ubuntu-20.04" \
--parameter flavor_id="m1.small" \
--parameter network_id="17eae9b6-2168-4a07-a0d3-66d5ad2a9f0e" \
```

# goryunov_infra_terraform_ansible
Git: https://github.com/Goryounov/artstyle-ci-cd

Shell stages:
```shell
#!/bin/bash

source ~/openrc.sh
export TF_VAR_openstack_auth_url=$OS_AUTH_URL
export TF_VAR_openstack_username=$OS_USERNAME
export TF_VAR_openstack_password=$OS_PASSWORD
export TF_VAR_openstack_domain_name=$OS_USER_DOMAIN_NAME

terraform init
terraform destroy -auto-approve
terraform apply -auto-approve
```

```shell
if [ -f inventory.ini ]; then
  rm inventory.ini
fi

INSTANCE_IP=$(terraform output -raw instance_ip)

echo "$INSTANCE_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/openstack ansible_ssh_common_args='-o StrictHostKeyChecking=no'" > inventory.ini
cat inventory.ini

echo "Check server on ${INSTANCE_IP}..."
until ssh -o StrictHostKeyChecking=no -i ~/.ssh/openstack ubuntu@"${INSTANCE_IP}" echo "SSH is available."; do
  if [ $? -eq 255 ]; then
    echo "SSH is unavailable. Retry..."
  fi
  sleep 10
done
```

```shell
ansible-playbook -i inventory.ini infra_playbook.yml
```

Files for archiving:
```shell
inventory.ini
```

# goryunov_deploy
Git: https://github.com/Goryounov/artstyle-ci-cd

Artifacts:
goryunov_build,
goryunov_infra_terraform_ansible

Shell stages:
```shell
ansible-playbook -i inventory.ini deploy_playbook.yml
```