REGION=us-central1
PROJECT=core-plate-443813-d1
REPO=workspace-dev-docker
KEY_JSON=./gcp/keys/service_account_dev.json

.PHONY: list-images

list-images:
	@echo "Activating service account..."
	gcloud auth activate-service-account --key-file=$(KEY_JSON)

	@echo "Listing Docker images..."
	gcloud artifacts docker images list $(REGION)-docker.pkg.dev/$(PROJECT)/$(REPO)