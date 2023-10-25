#!/bin/bash
set -e
gcloud auth activate-service-account --key-file=/sa.json
$@