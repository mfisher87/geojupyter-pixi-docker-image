# Probably the only way to share a value across stages without repeating it :(
# See: https://github.com/moby/moby/issues/37345
ARG DOCKER_WORKDIR=/workdir

# -----------------------------------------------------------------------------
# Build stage: Build pixi environment, create activation script
# -----------------------------------------------------------------------------
FROM ghcr.io/prefix-dev/pixi:noble AS build
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
FROM ubuntu:noble AS production
ARG DOCKER_WORKDIR
WORKDIR ${DOCKER_WORKDIR}

# Use bash as default shell instead of sh
ENV SHELL=/bin/bash

# Set up JupyterLab user
ENV NB_USER=jovyan
ENV NB_UID=1000
# RUN adduser --disabled-password --gecos "Default Jupyter user" ${NB_USER}
RUN useradd --create-home --comment "Default Jupyter user" --shell ${SHELL} ${NB_USER}

# Copy environment and activation script from build stage
COPY --from=build --chown=${NB_UID}:${NB_UID} ${DOCKER_WORKDIR}/.pixi/envs/default ./.pixi/envs/default
COPY --from=build --chown=${NB_UID}:${NB_UID} --chmod=0755 /entrypoint.sh /entrypoint.sh

# Don't buffer Python stdout/stderr output
ENV PYTHONBUFFERED=1

USER ${NB_USER}

ENTRYPOINT [ "/entrypoint.sh" ]
EXPOSE 8888
CMD ["jupyter", "lab", "--no-browser", "--ip=0.0.0.0"]
