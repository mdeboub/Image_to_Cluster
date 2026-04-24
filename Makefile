.PHONY: all build import deploy forward clean

all: build import deploy forward

build:
	@echo "==> Build de l'image avec Packer..."
	cd packer && packer init . && packer build nginx.pkr.hcl

import:
	@echo "==> Import de l'image dans K3d..."
	docker load < packer/nginx-custom.tar
	k3d image import nginx-custom:latest -c lab

deploy:
	@echo "==> Déploiement via Ansible..."
	ansible-playbook ansible/playbook.yml

forward:
	@echo "==> Port forwarding..."
	kubectl port-forward svc/nginx-custom 8080:80 >/tmp/nginx-custom.log 2>&1 &
	@echo "Ouvre l'onglet PORTS et rends le port 8080 public !"

clean:
	@echo "==> Nettoyage..."
	kubectl delete deployment nginx-custom || true
	kubectl delete service nginx-custom || true
