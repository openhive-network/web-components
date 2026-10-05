# The image AIDEV runs this project's suites in (`environment.image` in
# .aidev/project.yaml). Suites run with `--network none`, so everything an
# install needs is in the image: Node 24.21.0 (the NODEJS_VERSION CI's
# emsdk:5.0.2-4 image runs; this project builds no wasm, so the slim Node image
# rather than emsdk), pnpm (pinned by package.json's `packageManager`,
# installed through corepack) and a pnpm store filled from pnpm-lock.yaml.
# Build and pin it with .aidev/runtime/build.sh; see .aidev/README.md.
FROM node:24.21.0-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6

ENV HOME=/tmp \
    COREPACK_HOME=/opt/corepack \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    COREPACK_ENABLE_NETWORK=0 \
    npm_config_store_dir=/opt/pnpm-store \
    HUSKY=0 \
    DO_NOT_TRACK=1
# The suites are run as a plain command, as in the previous image; the base's
# docker-entrypoint.sh would prepend `node` to arguments it can't resolve.
ENTRYPOINT []

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml /tmp/pnpm-fetch/
RUN test "$(node --version)" = v24.21.0 \
    && cd /tmp/pnpm-fetch \
    && corepack enable \
    && COREPACK_ENABLE_NETWORK=1 corepack install -g "$(node -p "require('./package.json').packageManager")" \
    && pnpm fetch \
    && cd / && rm -rf /tmp/pnpm-fetch \
    && chmod -R a+rwX /opt/pnpm-store /opt/corepack
USER node
