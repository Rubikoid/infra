#!/usr/bin/env sh
set -eu

# metric name prefixes
SCSI="scsi_info"

echo "# HELP ${SCSI} Constant metric with metadata about the scsi drives"
echo "# TYPE ${SCSI} gauge"

for base_path in /sys/bus/scsi/drivers/sd/*:0:0:0; do
    scsi_path=$(basename "${base_path}")
    model=$(cat "${base_path}/model")
    state=$(cat "${base_path}/state")
    device=$(ls "${base_path}/block")

    fake_chip="target${scsi_path/:0:0:0/:0:0}_${scsi_path}"

    echo "${SCSI}{model=\"$model\",state=\"$state\",device=\"$device\",scsi_path=\"$scsi_path\",chip=\"$fake_chip\"} 1"
done;
