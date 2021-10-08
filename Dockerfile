FROM quay.io/powercloud/powervs-container-host:multi-arch

LABEL authors="Rafael Sene - rpsene@br.ibm.com"

WORKDIR /volume-delete

RUN ibmcloud plugin update power-iaas --force

ENV API_KEY=""

COPY ./delete_unused_volumes.sh .

RUN chmod +x ./delete_unused_volumes.sh

ENTRYPOINT ["/bin/bash", "-c", "./delete_unused_volumes.sh"]