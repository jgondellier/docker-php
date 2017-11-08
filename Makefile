SHELL := /bin/bash
.PHONY: pull build-nopull build test

PARENT_IMAGE := chialab/php
IMAGE := lamasbr/php
VERSION ?= 7.1-fpm

# Extensions.
EXTENSIONS := \
	bcmath \
	bz2 \
	calendar \
	iconv \
	imap \
	intl \
	gd \
	ldap \
	mbstring \
	mcrypt \
	memcached \
	mysqli \
	pdo_mysql \
	pdo_pgsql \
	pgsql \
	redis \
	soap \
	zip
ifneq ($(VERSION),$(filter 7.1, $(VERSION)))
	# Add more extensions to 5.x series images.
	EXTENSIONS += mysql
endif

# add opcache check to php version with zend opcache
ifeq ($(VERSION),$(filter 5.6 7.1, $(VERSION)))
	EXTENSIONS += OPcache
endif

build:
	@echo " =====> Building $(IMAGE):$(VERSION)..."
	@dir="$(subst -,/,$(VERSION))"; \
	if [[ "$(VERSION)" == 'latest' ]]; then \
		dir='.'; \
	fi; \
	docker build --quiet -t $(IMAGE):$(VERSION) $${dir}

test:
	@echo -e "=====> Testing loaded extensions... \c"
	@if [[ -z `docker images $(IMAGE) | grep "\s$(VERSION)\s"` ]]; then \
		echo 'FAIL [Missing image!!!]'; \
		exit 1; \
	fi
	@modules=`docker run --rm $(IMAGE):$(VERSION) php -m`; \
	for ext in $(EXTENSIONS); do \
		if [[ "$${modules}" != *"$${ext}"* ]]; then \
			echo "FAIL [$${ext}]"; \
			exit 1; \
		fi \
	done
	@if [[ "$(VERSION)" == *'-apache' ]]; then \
		apache=`docker run --rm $(IMAGE):$(VERSION) apache2ctl -M 2> /dev/null`; \
		if [[ "$${apache}" != *'rewrite_module'* ]]; then \
			echo 'FAIL [mod_rewrite]'; \
			exit 1; \
		fi \
	fi
	@if [[ -z `docker run --rm $(IMAGE):$(VERSION) composer --version 2> /dev/null | grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
		echo 'FAIL [Composer]'; \
		exit 1; \
	fi
	@echo 'OK'
