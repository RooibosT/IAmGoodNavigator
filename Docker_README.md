# Docker Setup for Isaac Sim Navigation Demo

This project must be run inside Docker. Do not install Isaac Sim, conda, or Python packages directly on the host machine.

## Host Requirements

Install only these on the host:

- NVIDIA driver
- Docker
- NVIDIA Container Toolkit

The Isaac Sim runtime and Python packages are provided inside the container image.

## Start the Docker Environment

From the repository root:

```bash
chmod +x run_docker.sh
./run_docker.sh
```

The script starts an interactive shell in:

```bash
/workspace/IAmGoodNavigator
```

The script builds a project image from the official Isaac Sim 4.5.0 image, then opens an interactive shell in it.

Base image:

```bash
nvcr.io/nvidia/isaac-sim:4.5.0
```

Project image:

```bash
goodnav-isaac:4.5.0
```

You can override the base image if needed:

```bash
ISAAC_SIM_BASE_IMAGE=nvcr.io/nvidia/isaac-sim:4.5.0 ./run_docker.sh
```

## GPU and CPU Selection

By default, the container can see all GPUs:

```bash
./run_docker.sh
```

To use one specific GPU on a 4-GPU server:

```bash
GPU_IDS=0 ./run_docker.sh
GPU_IDS=1 ./run_docker.sh
GPU_IDS=2 ./run_docker.sh
GPU_IDS=3 ./run_docker.sh
```

To expose multiple GPUs:

```bash
GPU_IDS=0,1 ./run_docker.sh
```

To limit CPU cores for the container, use `CPU_CORES`. This is the Docker-native equivalent of applying `taskset -c 0-10` to the workload:

```bash
CPU_CORES=0-10 ./run_docker.sh
```

You can combine both:

```bash
GPU_IDS=2 CPU_CORES=0-10 ./run_docker.sh
```

## Remote GUI from SSH

If you SSH into the GPU server from your local desktop, there are three practical ways to see the Isaac Sim GUI.

### Option 1: SSH X11 Forwarding

This can work, but Isaac Sim is a heavy GPU GUI application, so it may be slow or fail depending on your local X server, SSH settings, and network latency.

From your local desktop:

```bash
ssh -Y user@gpu-server
```

Then on the GPU server:

```bash
echo $DISPLAY
GPU_IDS=0 CPU_CORES=0-10 ./run_docker.sh
```

`run_docker.sh` forwards `DISPLAY` and mounts `XAUTHORITY` when available, so Docker can use the SSH-forwarded X session.

### Option 2: Remote Desktop

For interactive navigation, this is usually the most reliable option. Use a remote desktop solution such as NoMachine, NICE DCV, TurboVNC + VirtualGL, or an existing server-provided desktop session. Then run:

```bash
GPU_IDS=0 CPU_CORES=0-10 ./run_docker.sh
```

inside that remote desktop terminal.

This is better for the current demo because `demo.py` opens both the Isaac Sim window and separate `tkinter` instruction/result windows.

### Option 3: Isaac Sim WebRTC Streaming

Isaac Sim also supports remote livestreaming through the Isaac Sim WebRTC Streaming Client. This is useful for remote rendering, but the current `demo.py` uses separate `tkinter` windows, which are not part of the Isaac Sim viewport stream. Use this only if the demo UI is changed to avoid external `tkinter` windows or to show instructions inside Isaac Sim.

## Python Environment

Do not create a host conda environment. This Docker setup uses Isaac Sim's bundled Python:

```bash
/isaac-sim/python.sh
```

The custom image installs these dependencies into that Python environment at build time:

- `pandas`
- `scipy==1.10.1`
- `python3-tk` / `_tkinter` support for the instruction and result popup windows

So you do not need to run `pip install` every time you enter the container.

The README's PyTorch packages are not imported by the current `demo.py`. If you need them for future code, build the image with:

```bash
BUILD_WITH_TORCH=1 ./run_docker.sh
```

That uses a separate default image tag:

```bash
goodnav-isaac:4.5.0-torch
```

That installs:

- `torch==2.5.1`
- `torchvision==0.20.1`
- `torchaudio==2.5.1`

The packages are installed inside the Docker image, not on the host.

To force a rebuild:

```bash
FORCE_BUILD=1 ./run_docker.sh
```

If you see `ModuleNotFoundError: No module named '_tkinter'`, exit the container and rebuild the image:

```bash
exit
FORCE_BUILD=1 ./run_docker.sh
```

## Prepare Scene Data

If the scene files are already present, you can skip this step. This repository should contain files like:

```bash
kujiale_0010/
demo_scene.zip
```

If you need to download them again, run this from inside the container:

```bash
cd /workspace
bash IAmGoodNavigator/download.sh
cd /workspace/IAmGoodNavigator
```

`download.sh` expects to be launched from the parent directory because it runs `cd IAmGoodNavigator`.

## Run a Demo Episode

Inside the container:

```bash
cd /workspace/IAmGoodNavigator
/isaac-sim/python.sh demo.py --task fine --index 0 --work_dir ./myresults
```

For a coarse-grained episode:

```bash
/isaac-sim/python.sh demo.py --task coarse --index 0 --work_dir ./myresults
```

Valid values:

- `--task fine` or `--task coarse`
- `--index 0` through `--index 9`
- `--work_dir` is where trajectory CSV results are saved

## Simulator Controls

When Isaac Sim opens:

1. Click `Perspective` near the top of the viewport.
2. Select `Cameras`.
3. Select `FloatingCamera`.

Controls:

- `W`: move forward
- `S`: move backward
- `A`: turn left
- `D`: turn right
- `Enter`: finish the episode and evaluate the trajectory

## Notes

`run_docker.sh` configures:

- GPU access with `--gpus`, controlled by `GPU_IDS`
- CPU core pinning with `--cpuset-cpus`, controlled by `CPU_CORES`
- X11 GUI forwarding for Isaac Sim
- project mount at `/workspace/IAmGoodNavigator`
- persistent Isaac Sim cache/log/data directories under `$HOME/docker/isaac-sim`
- automatic image build when `goodnav-isaac:4.5.0` does not exist

If the Isaac Sim window does not appear, check:

```bash
echo $DISPLAY
xhost +local:docker
nvidia-smi
```

If GPU access fails inside Docker, fix the NVIDIA Container Toolkit setup before running the demo.
