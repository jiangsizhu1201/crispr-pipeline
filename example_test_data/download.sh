#!/bin/bash

IGVF_ACCESS_KEY=OMYEHTNY
IGVF_SECRET_KEY=ie6esgatnahb6tom
BUCKET_PATH="gs://igvf-pertub-seq-pipeline-data/data/fastq_files/"

ACCESSIONS=(IGVFFI6960ZMPS IGVFFI9965AAGO IGVFFI5143MAZQ IGVFFI5337NVTZ IGVFFI5784XOGQ IGVFFI6503CKFR IGVFFI3401IECW IGVFFI3487YJIM)

for ACCESSION in "${ACCESSIONS[@]}"; do
    # Stream download directly to Google Cloud Storage bucket using curl and gsutil
    curl -L -u "${IGVF_ACCESS_KEY}:${IGVF_SECRET_KEY}" \
        "https://api.data.igvf.org/sequence-files/${ACCESSION}/@@download/${ACCESSION}.fastq.gz" \
        | gsutil cp - "${BUCKET_PATH}${ACCESSION}.fastq.gz"

    # Output status message
    echo "Downloaded ${ACCESSION}.fastq.gz to ${BUCKET_PATH}"
done
