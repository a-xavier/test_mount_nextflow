nextflow.enable.dsl=2

params.scratch_path   = params.scratch_path ?: '/scratch'
params.min_scratch_gb = params.min_scratch_gb ?: 350

workflow {
    check_storage()
}

process check_storage {
    tag "storage-audit"
    container '419387107450.dkr.ecr.ap-southeast-2.amazonaws.com/portalseq/vep:latest'
    
    // We don't need 'containerOptions' mounts anymore because 
    // Nextflow's 'scratch' directive handles the directory creation.

    publishDir "s3://test-nextflow-pipeline/reports/", mode: 'copy'

    output:
    path "disk_report.txt"

    script:
    """
    {
      echo "=== Storage Audit Report ==="
      echo "Date: \$(date)"
      echo "Hostname: \$(hostname)"
      echo "User: \$(id)"
      echo ""
      echo "=== Disk Space (df -h) ==="
      # Look for the '/' mount - it should now be ~400G
      df -h /
      echo ""
      echo "=== Mount Points (lsblk) ==="
      lsblk
      echo ""
      echo "=== Permissions for /mnt/scratch ==="
      # This checks the host directory we created in User Data
      ls -ld /mnt/scratch || echo "/mnt/scratch not visible"
      echo ""
      echo "=== Write Test ==="
      # Attempt to create a 100MB dummy file to prove it works
      dd if=/dev/zero of=/mnt/scratch/test_write.img bs=1M count=100
      echo "Write test successful."
      rm /mnt/scratch/test_write.img
    } > disk_report.txt
    """
}