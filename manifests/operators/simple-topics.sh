#!/bin/bash

cat <<YAML
- type: replace
  path: /instance_groups/name=kafka/jobs/name=kafka/properties?/topics
  value:
YAML
for topic_name in $@; do
  cat <<YAML
  - name: $topic_name
    replication_factor: 1
    partitions: 1
YAML
done
