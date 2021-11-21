# make sure you have docker runtime set as nvidia-runtime
# docker build --no-cache --tag camerasimulation/pbrt-v4-gpu `pwd`
docker build --tag camerasimulation/pbrt-v4-gpu-ampere `pwd`
# docker build --tag camerasimulation/pbrt-v4-gpu-ampere `pwd`
# docker push camerasimulation/pbrt-v4-gpu

