# syntax=docker/dockerfile:1.13.0
ARG username=worker
ARG work_dir=/home/$username/work
ARG outcome=pass

FROM --platform=$BUILDPLATFORM bash:5.2.37-alpine3.22 AS base_builder

RUN apk add --no-cache curl

ARG username
ARG gid=2000
ARG uid=2001

RUN addgroup --system $username --gid $gid && \
    adduser --system $username --ingroup $username --uid $uid

USER $username

ARG work_dir
RUN mkdir -p $work_dir
WORKDIR $work_dir

ARG cache_dir=/home/$username/.build/cache

RUN mkdir -p $cache_dir

COPY --link --chown=$uid internal_build.sh internal_build.sh

RUN --mount=type=cache,gid=$gid,uid=$uid,target=$cache_dir \
    ./internal_build.sh --dry-run

COPY --link --chown=$uid . .

FROM --platform=$BUILDPLATFORM base_builder AS unfailing-build
ARG CACHE_BUSTER

RUN echo "$CACHE_BUSTER" > /dev/null

ARG outcome

RUN --mount=type=cache,gid=$gid,uid=$uid,target=$cache_dir \
    --network=none \
    ./internal_build.sh "$outcome" --offline || (status=$?; mkdir -p build && echo $status > build/failed)


FROM --platform=$BUILDPLATFORM scratch AS build-output
ARG work_dir

COPY --link --from=unfailing-build $work_dir/build .


FROM --platform=$BUILDPLATFORM base_builder AS builder

ARG outcome

RUN --mount=type=cache,gid=$gid,uid=$uid,target=$cache_dir \
    --network=none \
    ./internal_build.sh "$outcome" --offline


FROM --platform=$BUILDPLATFORM scratch
ARG work_dir

COPY --link --from=builder $work_dir/build .
