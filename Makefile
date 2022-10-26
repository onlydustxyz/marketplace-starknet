start:
	@ARM_TAG=$([ `uname -m` = arm64 ] && echo -arm) 
	ARM_TAG=${ARM_TAG} docker-compose up -d
	@./scripts/deploy_accounts.sh

stop:
	docker-compose down -v 
	@./scripts/cleanup.sh

build: 
	@./scripts/compile.sh

deploy: 
	@./scripts/deploy_ctf_contracts.sh

verify:
	@./scripts/verify_hack.sh

.PHONY: build
