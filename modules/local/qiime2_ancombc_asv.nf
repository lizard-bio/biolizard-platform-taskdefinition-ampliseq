process QIIME2_ANCOMBC_ASV {
    tag "${table.baseName}"
    label 'process_medium'
    label 'single_cpu'
    label 'process_long'
    label 'error_ignore'

    container "qiime2/core:2023.7"

    input:
    tuple path(metadata), path(table)

    output:
    path("ancom/*")     , emit: ancom
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "QIIME2 does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    """
    export XDG_CONFIG_HOME="./xdgconfig"
    export MPLCONFIGDIR="./mplconfigdir"
    export NUMBA_CACHE_DIR="./numbacache"

    qiime composition add-pseudocount \\
        --i-table ${table} \\
        --o-composition-table comp-${table}
    qiime composition ancombc \\
        --i-table comp-${table} \\
        --m-metadata-file ${metadata} \\
        --p-formula ${table.baseName} \\
        --o-differentials ancombc-${table.baseName}.qza
    qiime tools export --input-path ancombc-${table.baseName}.qza \\
        --output-path ancom/ancombc-${table.baseName}-ASV

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        qiime2: \$( qiime --version | sed '1!d;s/.* //' )
    END_VERSIONS
    """
}
