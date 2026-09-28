# ba0fde3d-bee7-4307-b97b-17d0d20aff50
# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx

COPY files/system /system_files/
COPY --chmod=0755 files/scripts /build_files/
COPY *.pub /keys/
COPY env /env

# Base Image
FROM quay.io/almalinuxorg/almalinux-bootc:10@sha256:4e1c91ec850387222a7a0d168b30e7acd4d2c74b8e63c1850e86b1d39de99e85

ARG IMAGE_NAME
ARG IMAGE_REGISTRY
ARG VARIANT

RUN --mount=type=tmpfs,dst=/opt \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=pull_secret,dst=/run/secrets/auth.json,required=false \
    /ctx/build_files/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
