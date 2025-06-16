FROM ghcr.io/prefix-dev/pixi:latest as build

WORKDIR /workdir
COPY . .

RUN pixi install && rm -rf ~/.cache/rattler

# Don't buffer Python stdout/stderr output
ENV PYTHONBUFFERED=1

# Set up shell activation
RUN pixi shell-hook -s bash > /shell-hook
RUN echo "#!/bin/bash" > /entrypoint.sh
RUN cat /shell-hook >> /entrypoint.sh
RUN echo 'exec "$@"' >> /entrypoint.sh


FROM ubuntu:24.04 as production

ENV DOCKER_WORKDIR=/srv/repo
WORKDIR ${DOCKER_WORKDIR}

COPY --from=build /workdir/.pixi/envs/default ./.pixi/envs/default
COPY --from=build --chmod=0755 /entrypoint.sh /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["jupyter", "notebook", "--ip", "0.0.0.0"]
