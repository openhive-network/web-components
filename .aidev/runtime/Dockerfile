# The image AIDEV runs this project's suites in (`environment.image` in
# .aidev/project.yaml). Suites run with `--network none`, so everything an
# install needs is in the image: Node 24.21.0 (CI's emsdk:5.0.2-4 image, the
# EMSCRIPTEN_IMAGE_TAG of .gitlab-ci.yml's common-ci-configuration ref, so the
# suites run the Node CI runs), pnpm (pinned by package.json's
# `packageManager`, installed through corepack) and a pnpm store filled from
# pnpm-lock.yaml. Build and pin it with .aidev/runtime/build.sh; see
# .aidev/README.md.
FROM registry.gitlab.syncad.com/hive/common-ci-configuration/emsdk:5.0.2-4@sha256:966dd9e9da494d184fcc7f622bb24d93c41b8d58c814156aa79cd1d70f31d9ab

# CI selects this Node with `nvm use "$NODEJS_VERSION"`. The image's entrypoint
# (emsdk_env.sh) rewrites PATH, and emsdk bundles its own Node 22, so the PATH
# is set here and the entrypoint dropped.
ENV PATH=/home/emscripten/.nvm/versions/node/v24.21.0/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    HOME=/tmp \
    COREPACK_HOME=/opt/corepack \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    COREPACK_ENABLE_NETWORK=0 \
    npm_config_store_dir=/opt/pnpm-store \
    HUSKY=0 \
    DO_NOT_TRACK=1
ENTRYPOINT []

USER root
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml /tmp/pnpm-fetch/
RUN test "$(node --version)" = v24.21.0 \
    && cd /tmp/pnpm-fetch \
    && corepack enable \
    && COREPACK_ENABLE_NETWORK=1 corepack install -g "$(node -p "require('./package.json').packageManager")" \
    && pnpm fetch \
    && cd / && rm -rf /tmp/pnpm-fetch \
    && chmod -R a+rwX /opt/pnpm-store /opt/corepack
USER emscripten
