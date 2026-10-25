# The image AIDEV runs this project's suites in (`environment.image` in
# .aidev/project.yaml). Suites run with `--network none`, so everything an
# install needs is in the image: ccc's node-test-tools (the node and pnpm
# versions ccc's docker-bake.hcl sets, the same ones its emsdk CI image carries;
# this project builds no wasm, so not emsdk itself) and a pnpm store filled from
# pnpm-lock.yaml. Build and pin it with .aidev/runtime/build.sh; see .aidev/README.md.
FROM registry.gitlab.syncad.com/hive/common-ci-configuration/node-test-tools:develop@sha256:c15f6782c675ddbe8a5d5b05cfa27cfa7b606ecd8bc67a3b5d0c2206f2733994

ENV HOME=/tmp \
    npm_config_store_dir=/opt/pnpm-store \
    HUSKY=0 \
    DO_NOT_TRACK=1
# The suites are run as a plain command.
ENTRYPOINT []

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml /tmp/pnpm-fetch/
RUN cd /tmp/pnpm-fetch \
    && pnpm fetch \
    && cd / && rm -rf /tmp/pnpm-fetch \
    && chmod -R a+rwX /opt/pnpm-store
USER ubuntu
