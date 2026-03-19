nextflow.enable.dsl=2

process CHECK_STORAGE_LIVE {
    container 'amazonlinux:2023'
    
    // Using the boolean true is more robust in Nextflow configs
    scratch true 

    script:
    """
    echo "===================================================="
    echo "STATUS: STARTING STORAGE AUDIT"
    echo "===================================================="
    echo "TIMESTAMP: \$(date)"
    echo "USER:      \$(id)"
    echo ""

    echo "--- 1. MOUNTED FILESYSTEMS (df -h) ---"
    # This will show if / is ~400G
    df -h /
    echo ""

    echo "--- 2. TASK DIRECTORY SPACE (df -h .) ---"
    # This confirms the space available to the running container
    df -h .
    echo ""

    echo "--- 3. PHYSICAL HARDWARE (lsblk) ---"
    # This proves the 400G EBS volume is attached as the root
    lsblk
    echo ""

    echo "--- 4. WRITE CAPACITY TEST ---"
    echo "Creating 1GB test file in current work dir..."
    dd if=/dev/zero of=test_1gb.bin bs=1M count=1000 status=progress
    echo ""
    echo "Write successful. Deleting test file."
    rm test_1gb.bin
    
    echo "===================================================="
    echo "STATUS: AUDIT COMPLETE"
    echo "===================================================="
    """
}

workflow {
    CHECK_STORAGE_LIVE()
}