# make sure you have docker runtime set as nvidia-runtime
#docker build --no-cache --tag camerasimulation/pbrt-v4-gpu-ampere `pwd`
docker build -f Dockerfile.cpu --tag digitalprodev/pbrt-v4-cpu `pwd`
docker push digitalprodev/pbrt-v4-cpu:latest


