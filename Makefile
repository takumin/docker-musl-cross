#
# Environment Variables
#

TAG ?= takumi/mruby-musl-cross

TARGET ?= x86_64-multilib-linux-musl

BUILD_UID ?= $(shell id -u)
BUILD_GID ?= $(shell id -g)

TARBALLS_DIR ?= $(CURDIR)/.tarballs

#
# Common Config
#

RUN_ARGS ?= -e TARGET=$(TARGET)
BUILD_ARGS ?= --build-arg TARGET=$(TARGET)

ifneq (x$(BUILD_UID)x,xx)
RUN_ARGS += -e BUILD_UID=$(BUILD_UID)
BUILD_ARGS += --build-arg BUILD_UID=$(BUILD_UID)
endif

ifneq (x$(BUILD_GID)x,xx)
RUN_ARGS += -e BUILD_GID=$(BUILD_GID)
BUILD_ARGS += --build-arg BUILD_GID=$(BUILD_GID)
endif

ifneq (x$(TARBALLS_DIR)x,xx)
RUN_ARGS += -v $(TARBALLS_DIR):/cross/src:rw
endif

#
# Proxy Config
#

ifneq (x${no_proxy}x,xx)
RUN_ARGS += -e no_proxy=${no_proxy}
BUILD_ARGS += --build-arg no_proxy=${no_proxy}
endif
ifneq (x${NO_PROXY}x,xx)
RUN_ARGS += -e NO_PROXY=${NO_PROXY}
BUILD_ARGS += --build-arg NO_PROXY=${NO_PROXY}
endif

ifneq (x${ftp_proxy}x,xx)
RUN_ARGS += -e ftp_proxy=${ftp_proxy}
BUILD_ARGS += --build-arg ftp_proxy=${ftp_proxy}
endif
ifneq (x${FTP_PROXY}x,xx)
RUN_ARGS += -e FTP_PROXY=${FTP_PROXY}
BUILD_ARGS += --build-arg FTP_PROXY=${FTP_PROXY}
endif

ifneq (x${http_proxy}x,xx)
RUN_ARGS += -e http_proxy=${http_proxy}
BUILD_ARGS += --build-arg http_proxy=${http_proxy}
endif
ifneq (x${HTTP_PROXY}x,xx)
RUN_ARGS += -e HTTP_PROXY=${HTTP_PROXY}
BUILD_ARGS += --build-arg HTTP_PROXY=${HTTP_PROXY}
endif

ifneq (x${https_proxy}x,xx)
RUN_ARGS += -e https_proxy=${https_proxy}
BUILD_ARGS += --build-arg https_proxy=${https_proxy}
endif
ifneq (x${HTTPS_PROXY}x,xx)
RUN_ARGS += -e HTTPS_PROXY=${HTTPS_PROXY}
BUILD_ARGS += --build-arg HTTPS_PROXY=${HTTPS_PROXY}
endif

#
# Debian Mirror
#

ifneq (x${DEBIAN_MIRROR}x,xx)
RUN_ARGS += -e DEBIAN_MIRROR=${DEBIAN_MIRROR}
BUILD_ARGS += --build-arg DEBIAN_MIRROR=${DEBIAN_MIRROR}
endif
ifneq (x${DEBIAN_SECURITY}x,xx)
RUN_ARGS += -e DEBIAN_SECURITY=${DEBIAN_SECURITY}
BUILD_ARGS += --build-arg DEBIAN_SECURITY=${DEBIAN_SECURITY}
endif

#
# Default Rules
#

.PHONY: all
all: build

#
# Build Rules
#

.PHONY: build
build:
	@docker build -t $(TAG):$(TARGET) $(BUILD_ARGS) .

#
# Running Rules
#

.PHONY: run
run:
	@docker run --rm -i -t $(RUN_ARGS) $(TAG):$(TARGET) bash -il

#
# Clean Rules
#

.PHONY: clean
clean:
	@docker system prune --volumes --force
