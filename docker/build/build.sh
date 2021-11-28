# make sure you have docker runtime set as nvidia-runtime
docker build --tag digitalprodev/pbrt-v4-gpu-ampere-bg `pwd`
# docker build --no-cache --tag camerasimulation/pbrt-v4-gpu-ampere-x64 `pwd`
# docker build --tag camerasimulation/pbrt-v4-gpu-ampere `pwd`
docker push digitalprodev/pbrt-v4-gpu-ampere-bg

