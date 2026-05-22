ARG BASE_IMAGE=nvcr.io/nvidia/isaac-sim:4.5.0
FROM ${BASE_IMAGE}

ARG INSTALL_TORCH=false

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1

RUN /isaac-sim/python.sh -m pip install --upgrade pip && \
    /isaac-sim/python.sh -m pip install \
      pandas \
      scipy==1.10.1

RUN if [ "${INSTALL_TORCH}" = "true" ]; then \
      /isaac-sim/python.sh -m pip install \
        --index-url https://download.pytorch.org/whl/cu118 \
        torch==2.5.1 \
        torchvision==0.20.1 \
        torchaudio==2.5.1; \
    fi

WORKDIR /workspace/IAmGoodNavigator
