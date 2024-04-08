#!/bin/bash
oc debug --as-root $(oc get node -o name | head -n 1) -- chroot /host  /usr/local/bin/cluster-backup.sh /home/core/assets/backup
