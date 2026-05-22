ARG BASE_IMAGE=nvcr.io/nvidia/isaac-sim:4.5.0
FROM ${BASE_IMAGE}

ARG INSTALL_TORCH=false

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      python3-tk \
      tcl \
      tk && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /isaac-sim/kit/python/lib/python3.10/lib-dynload && \
    TKINTER_SO="$(find /usr/lib -name '_tkinter*.so' -print -quit)" && \
    if [ -z "$TKINTER_SO" ]; then \
      echo "Could not find _tkinter shared library after installing python3-tk" >&2; \
      exit 1; \
    fi && \
    ln -sf "$TKINTER_SO" /isaac-sim/kit/python/lib/python3.10/lib-dynload/

RUN /isaac-sim/python.sh -m pip install --upgrade pip && \
    /isaac-sim/python.sh -m pip install \
      pandas \
      scipy==1.10.1

RUN /isaac-sim/python.sh -c "import tkinter, _tkinter"

RUN if [ "${INSTALL_TORCH}" = "true" ]; then \
      /isaac-sim/python.sh -m pip install \
        --index-url https://download.pytorch.org/whl/cu118 \
        torch==2.5.1 \
        torchvision==0.20.1 \
        torchaudio==2.5.1; \
    fi

WORKDIR /workspace/IAmGoodNavigator
