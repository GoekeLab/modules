// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process GATK4_SPLITNCIGARREADS {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? 'bioconda::gatk4=4.1.9.0' : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container 'https://depot.galaxyproject.org/singularity/gatk4:4.1.9.0--py39_0'
    } else {
        container 'quay.io/biocontainers/gatk4:4.1.9.0--py39_0'
    }

    input:
    tuple val(meta), path(bam)
    tuple path(fasta), path(fai), path(dict)

    output:
    tuple val(meta), path('*.split_cigar.bam'), emit: bam
    path  '*.version.txt'                     , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = options.suffix ? "${meta.id}.${options.suffix}" : "${meta.id}"
    """
    gatk SplitNCigarReads \\
        -R $fasta \\
        -I $bam \\
        -O ${prefix}.split_cigar.bam \\
        $options.args

    gatk --version | grep Picard | sed "s/Picard Version: //g" > ${software}.version.txt
    """
}
