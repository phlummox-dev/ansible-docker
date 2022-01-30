
.PHONY: docker-build docker-shell print-build-args \
	default build \
	print-docker-hub-image

SHELL=bash

default:
	echo pass

######
# docker stuff

REPO=phlummox

IMAGE_NAME=ansible

IMAGE_VERSION=0.1.0

print-image-name:
	@echo $(IMAGE_NAME)

print-image-version:
	@echo $(IMAGE_VERSION)

GIT_REF=$(shell git rev-parse HEAD)
GIT_COMMIT_DATE=$(shell git show -s --format=%cI $(GIT_REF))
GIT_TAGS=$(shell git tag -l)

print-build-args:
	@printf '%s %s\n' '--build-arg GIT_REF=$(GIT_REF)' \
		'--build-arg GIT_COMMIT_DATE=$(GIT_COMMIT_DATE)' \
		'--build-arg VERSION=$(IMAGE_VERSION)'

print-docker-hub-image:
	@printf '%s' "$(REPO)/$(IMAGE_NAME)"

#docker-build:
#	set -x; \
#	build_args="$$(make --no-print-directory --quiet print-build-args)"; \
#	docker build --pull $$build_args \
#		-f .gitpod.Dockerfile $(TAGS_TO_ADD) $(TAGS_IN) -t $(IMAGE):$(VERSION) .

docker-build:
	docker build \
		-f Dockerfile $(TAGS_TO_ADD) $(TAGS_IN) \
		-t $(REPO)/$(IMAGE_NAME):$(IMAGE_VERSION) .

REMOVE_AFTER=--rm

docker-shell:
	-docker rm android-studio-ctr
	docker -D run -e DISPLAY -it --net=host  \
		--name 'android-studio-ctr' \
		$(DOCKER_LIMITS) \
		-v $$HOME/dev/:/home/dev \
		-v $$PWD:/work --workdir=/work \
		$(MOUNT)  $(DEVICES)  --env QT_X11_NO_MITSHM=1 \
		$(REPO)/$(IMAGE_NAME):$(IMAGE_VERSION) bash


