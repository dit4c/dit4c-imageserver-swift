.DEFAULT_GOAL = all
.PHONY = clean all deploy

NAME=dit4c-imageserver-filesystem
BASE_DIR = .
BUILD_DIR = ${BASE_DIR}/build
OUT_DIR = ${BASE_DIR}/dist
TARGET_IMAGE = ${OUT_DIR}/${NAME}.linux.amd64.aci

MKDIR_P = mkdir -p
GPG=gpg2

NGINX_DOCKER_IMAGE=nginx:alpine
NGINX_ACI=${BUILD_DIR}/library-nginx-alpine.aci

ACBUILD=${BUILD_DIR}/acbuild
ACBUILD_VERSION=0.4.0
ACBUILD_URL=https://github.com/containers/build/releases/download/v${ACBUILD_VERSION}/acbuild-v${ACBUILD_VERSION}.tar.gz

DOCKER2ACI=${BUILD_DIR}/docker2aci
DOCKER2ACI_VERSION=0.14.0
DOCKER2ACI_URL=https://github.com/appc/docker2aci/releases/download/v${DOCKER2ACI_VERSION}/docker2aci-v${DOCKER2ACI_VERSION}.tar.gz

CONFD=${BUILD_DIR}/confd
CONFD_VERSION=0.11.0
CONFD_URL=https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64

${BUILD_DIR}:
	${MKDIR_P} ${BUILD_DIR}

${OUT_DIR}:
	${MKDIR_P} ${OUT_DIR}

clean:
	rm -rf ${BUILD_DIR} ${OUT_DIR}

${ACBUILD}: | ${BUILD_DIR}
	curl -sL ${ACBUILD_URL} | tar xz --touch --strip-components=1 -C ${BUILD_DIR}

${DOCKER2ACI}: | ${BUILD_DIR}
	curl -sL ${DOCKER2ACI_URL} | tar xz --touch --strip-components=1 -C ${BUILD_DIR}

${CONFD}: | ${BUILD_DIR}
	curl -sL -o ${CONFD} ${CONFD_URL}
	chmod +x ${CONFD}

${NGINX_ACI}: ${DOCKER2ACI}
	cd ${BUILD_DIR} && ../${DOCKER2ACI} docker://${NGINX_DOCKER_IMAGE}

${TARGET_IMAGE}: ${ACBUILD} ${NGINX_ACI} ${CONFD} etc start.sh | ${OUT_DIR}
	sudo rm -rf .acbuild
	sudo ${ACBUILD} --debug begin ${NGINX_ACI}
	sudo ${ACBUILD} --debug copy ${CONFD} /usr/local/bin/confd
	sudo ${ACBUILD} --debug copy-to-dir etc/confd /etc
	sudo ${ACBUILD} --debug copy start.sh /start
	sudo ${ACBUILD} --debug set-exec /start
	sudo ${ACBUILD} --debug set-name ${NAME}
	sudo ${ACBUILD} --debug environment add PORTAL_URI https://dit4c.net
	sudo ${ACBUILD} --debug mount add data /data
	sudo ${ACBUILD} --debug write --overwrite $@
	sudo ${ACBUILD} --debug end
	sudo chown $(shell id -u):$(shell id -g) $@

${TARGET_IMAGE}.asc: ${TARGET_IMAGE} signing.key
	$(eval TMP_KEYRING := $(shell mktemp -p ${BUILD_DIR}))
	$(eval GPG_FLAGS := --batch --no-default-keyring --keyring $(TMP_KEYRING) )
	$(GPG) $(GPG_FLAGS) --import signing.key
	$(GPG) $(GPG_FLAGS) --armour --detach-sign $<
	rm $(TMP_KEYRING)

all: ${TARGET_IMAGE}

deploy: ${TARGET_IMAGE} ${TARGET_IMAGE}.asc
