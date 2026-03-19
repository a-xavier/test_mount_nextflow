nextflow.enable.dsl=2

params.scratch_path   = params.scratch_path ?: '/scratch'
params.min_scratch_gb = params.min_scratch_gb ?: 350

workflow {
    scratch_check()
}

process scratch_check {
    tag "scratch-check"

    container 'debian:stable-slim'

    cpus 1
    memory '1 GB'
    time '10 min'
    errorStrategy 'terminate'

    output:
    path "scratch_check_report.txt"

    script:
    """
    set -euo pipefail

    SCRATCH="${params.scratch_path}"
    MIN_GB="${params.min_scratch_gb}"

    {
      echo "=== scratch check report ==="
      echo "hostname: \$(hostname)"
      echo "pwd: \$(pwd)"
      echo "scratch_path: \$SCRATCH"
      echo "min_required_gb: \$MIN_GB"
      echo "date: \$(date -Is)"
      echo
      echo "=== mount info ==="
      if command -v findmnt >/dev/null 2>&1; then
        findmnt -T "\$SCRATCH" || true
      else
        grep " \$SCRATCH " /proc/mounts || true
      fi
      echo
      echo "=== df ==="
      df -h "\$SCRATCH" || true
      echo
      echo "=== ls -ld ==="
      ls -ld "\$SCRATCH" || true
    } > scratch_check_report.txt

    if [ ! -d "\$SCRATCH" ]; then
      echo "ERROR: \$SCRATCH does not exist" | tee -a scratch_check_report.txt >&2
      exit 1
    fi

    if command -v findmnt >/dev/null 2>&1; then
      if ! findmnt -T "\$SCRATCH" >/dev/null 2>&1; then
        echo "ERROR: \$SCRATCH is not mounted" | tee -a scratch_check_report.txt >&2
        exit 1
      fi
    else
      if ! grep -q " \$SCRATCH " /proc/mounts; then
        echo "ERROR: \$SCRATCH is not mounted" | tee -a scratch_check_report.txt >&2
        exit 1
      fi
    fi

    AVAIL_GB=\$(df -BG "\$SCRATCH" | awk 'NR==2 {gsub("G","",\$4); print \$4}')
    if [ -z "\$AVAIL_GB" ]; then
      echo "ERROR: could not determine available space on \$SCRATCH" | tee -a scratch_check_report.txt >&2
      exit 1
    fi

    echo "available_gb: \$AVAIL_GB" >> scratch_check_report.txt

    if [ "\$AVAIL_GB" -lt "\$MIN_GB" ]; then
      echo "ERROR: \$SCRATCH has only \${AVAIL_GB}G available, expected at least \${MIN_GB}G" | tee -a scratch_check_report.txt >&2
      exit 1
    fi

    TEST_FILE="\$SCRATCH/.nextflow_scratch_test_\$\$"
    echo "Writing test file: \$TEST_FILE" >> scratch_check_report.txt
    dd if=/dev/zero of="\$TEST_FILE" bs=1M count=10 status=none
    sync
    rm -f "\$TEST_FILE"

    echo "write_test: ok" >> scratch_check_report.txt
    echo "status: ok" >> scratch_check_report.txt
    """
}