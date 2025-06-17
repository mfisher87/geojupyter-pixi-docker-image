FROM ghcr.io/prefix-dev/pixi:noble AS build
LABEL "org.opencontainers.image.description"="A pixi-based Docker image for a robust GeoJupyter environment"

# Use bash as default shell instead of sh
ENV SHELL=/bin/bash
# Don't buffer Python stdout/stderr output
ENV PYTHONBUFFERED=1
# Don't prompt in apt commands
ENV DEBIAN_FRONTEND=noninteractive

# Set up JupyterLab user
ENV NB_USER=jovyan
ENV NB_UID=1000
ENV USER="${NB_USER}"
ENV HOME="/home/${NB_USER}"
RUN userdel ubuntu \
 && groupadd \
  --gid ${NB_UID} \
  ${NB_USER} \
 && useradd \
  --comment "Default Jupyter user" \
  --create-home \
  --no-log-init \
  --uid ${NB_UID} \
  --gid ${NB_UID} \
  --shell ${SHELL} \
  ${NB_USER}

ENV DOCKER_WORKDIR=/workdir
WORKDIR ${DOCKER_WORKDIR}

# Build the environment
COPY pixi.toml .
RUN pixi install \
 && rm -rf ~/.cache/rattler

# Set up shell activation script
ENV ENTRYPOINT_SCRIPT="/entrypoint.sh"
RUN pixi shell-hook -s bash > /shell-hook
RUN echo "#!/bin/bash" > ${ENTRYPOINT_SCRIPT}
RUN cat /shell-hook >> ${ENTRYPOINT_SCRIPT}
RUN echo 'exec "$@"' >> ${ENTRYPOINT_SCRIPT}
RUN chmod +x ${ENTRYPOINT_SCRIPT}

USER ${NB_USER}

WORKDIR "/home/${NB_USER}"
EXPOSE 8888
ENTRYPOINT ["/entrypoint.sh"]
CMD ["jupyter", "lab", "--no-browser", "--ip=0.0.0.0"]
