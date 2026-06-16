# ba0fde3d-bee7-4307-b97b-17d0d20aff50
# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx

COPY files/system /system_files/
COPY --chmod=0755 files/scripts /build_files/
COPY *.pub /keys/
COPY env /env

# Base Image
# Fork-specific: pin the amd64_v2 variant for older CPUs that only support x86-64-v2.
FROM quay.io/almalinuxorg/almalinux-bootc:10@sha256:ebe7e424bf74208011eeb9bbaa9541602881008acc21ad33a0c39cb3ec90e4fe

ARG IMAGE_NAME
ARG IMAGE_REGISTRY
ARG VARIANT

RUN --mount=type=tmpfs,dst=/opt \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=secret,id=pull_secret,dst=/run/secrets/auth.json,required=false \
    --mount=type=secret,id=mok_key,dst=/run/secrets/mok.key,required=false \
    /ctx/build_files/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
