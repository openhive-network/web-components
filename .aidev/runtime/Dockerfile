# The image AIDEV runs this project's suites in (`environment.image` in
# .aidev/project.yaml). Suites run with `--network none`, so everything an
# install needs is in the image: Node 20.18.3 (the NODEJS_VERSION of the
# emsdk:4.0.1-3 image .gitlab-ci.yml's common-ci-configuration ref names; that
# image is no longer in the registry and the project builds no wasm, so this
# is the plain Node image of the same version), pnpm (pinned by package.json's
# `packageManager`, installed through corepack) and a pnpm store filled from
# pnpm-lock.yaml. Build and pin it with .aidev/runtime/build.sh; see
# .aidev/README.md.
FROM node:20.18.3-bookworm-slim@sha256:ffc11dbf16dd0abcbb7b837410601b4d5592db2d03741e13a4a5336ab74d7ccb

ENV HOME=/tmp \
    COREPACK_HOME=/opt/corepack \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    COREPACK_ENABLE_NETWORK=0 \
    npm_config_store_dir=/opt/pnpm-store \
    HUSKY=0 \
    DO_NOT_TRACK=1

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml /tmp/pnpm-fetch/
RUN cd /tmp/pnpm-fetch \
    && corepack enable \
    && COREPACK_ENABLE_NETWORK=1 corepack install -g "$(node -p "require('./package.json').packageManager")" \
    && pnpm fetch \
    && cd / && rm -rf /tmp/pnpm-fetch \
    && chmod -R a+rwX /opt/pnpm-store /opt/corepack
