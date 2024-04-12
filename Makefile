DOCKER_IMAGE=dontpush.example/abuilder

VERSION=2.7.2

output/duplicacy-$(VERSION)-r0.apk: .docker-image.placeholder keys
	sed 's!{{version}}!$(VERSION)!' \
		APKBUILD.in > APKBUILD
	# Update checksums in APKBUILD
	docker run --rm \
		-v "$(PWD):/home/builder/package" \
		-v "$(PWD)/output:/packages" \
		$(DOCKER_IMAGE) checksum
	docker run --rm \
		-v "$(PWD):/home/builder/package" \
		-v "$(PWD)/output:/packages/builder/aarch64" \
		-e PACKAGER_PRIVKEY="/home/builder/package/$(shell ls -1 keys/*.rsa)" \
		$(DOCKER_IMAGE)
	$(RM) APKBUILD
	$(RM) output/APKINDEX.tar.gz

# Generate an ephemeral set of keys
keys: .docker-image.placeholder
	rm -rf keys
	mkdir -p keys
	docker run --rm \
		--entrypoint abuild-keygen \
		-v "$(PWD)/keys":/home/builder/.abuild \
		-e PACKAGER="Packager <packager@example.com>" \
		$(DOCKER_IMAGE) -n

.docker-image.placeholder: Dockerfile abuilder
	docker build -t $(DOCKER_IMAGE) .
	touch $@

.PHONY: clean
clean:
	rm -rf APKBUILD output keys .docker-image.placeholder
	docker rmi -f $(DOCKER_IMAGE)
