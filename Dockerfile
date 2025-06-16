# Probably the only way to share a value across stages without repeating it :(
# See: https://github.com/moby/moby/issues/37345
ARG DOCKER_WORKDIR=/workdir

# -----------------------------------------------------------------------------
# Build stage: Build pixi environment, create activation script
# -----------------------------------------------------------------------------
FROM ghcr.io/prefix-dev/pixi:latest AS build
ARG DOCKER_WORKDIR
WORKDIR ${DOCKER_WORKDIR}

# Build the environment
COPY pixi.toml .
RUN pixi install

# Set up shell activation script
RUN pixi shell-hook -s bash > /shell-hook
RUN echo "#!/bin/bash" > /entrypoint.sh
RUN cat /shell-hook >> /entrypoint.sh
RUN echo 'exec "$@"' >> /entrypoint.sh


# -----------------------------------------------------------------------------
# Production stage: Copy over Pixi environment & activation script, set up env
# -----------------------------------------------------------------------------
FROM ubuntu:24.04 AS production
ARG DOCKER_WORKDIR
WORKDIR ${DOCKER_WORKDIR}

# Copy environment and activation script from build stage
COPY --from=build ${DOCKER_WORKDIR}/.pixi/envs/default ./.pixi/envs/default
COPY --from=build --chmod=0755 /entrypoint.sh /entrypoint.sh

# Don't buffer Python stdout/stderr output
ENV PYTHONBUFFERED=1

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
