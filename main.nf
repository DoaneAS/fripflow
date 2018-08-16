#!/usr/bin/env nextflow

/*
vim: syntax=groovy
-*- mode: groovy;-*-
 *
 * Copyright (c) 2013-2017, Centre for Genomic Regulation (CRG).
 * Copyright (c) 2013-2017, Paolo Di Tommaso and the respective authors.
 *
 *   This file is part of 'Nextflow'.
 *
 *   Nextflow is free software: you can redistribute it and/or modify
 *   it under the terms of the GNU General Public License as published by
 *   the Free Software Foundation, either version 3 of the License, or
 *   (at your option) any later version.
 *
 *   Nextflow is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the GNU General Public License
 *   along with Nextflow.  If not, see <http://www.gnu.org/licenses/>.
 */ 
       //params.fragmentLength = 200

//params.index = '/home/asd2007/Scripts/nf/fripflow/sindex.tsv'
params.index = 'indexAll.tsv'


params.genome = 'hg38'
params.genomes = []

params.chrsz = params.genome ? params.genomes[ params.genome ].chrsz ?: false : false
params.encodedhs = params.genome ? params.genomes[ params.genome ].ENCODEDHS ?: false : false




encodedhs = file(params.encodedhs)


////// Print parameters ///////
log.info ''
log.info ''
log.info 'A T A C - Q C ~ FRiP Scores'
log.info '---------------------------------'
log.info ''
log.info "Index File             : ${params.index}"
log.info ''

index = file(params.index)

results_path = "$PWD/results"

// Clear pipeline.db file

////// Check input parameters //////

if (!params.index) {
  exit 1, "Please specify the input table file"
}

atacs = Channel
       .from(index.readLines())
       .map { line ->
       def list = line.split()
              def sname = file(list[0])
              def bam = file(list[1])
       println bam
       println sname
       [ sname, bam ]
}






process processbam {
    tag "$Sample"
    publishDir "$results_path/$Sample/$Sample", mode: 'copy'

    executor 'sge'
    cpus 8
    penv 'smp'
    clusterOptions '-l h_vmem=4G -l h_rt=16:00:00 -l athena=true'
    scratch true
    // cpus 8


    input:
    set Sample, file(nbam) from newbam

    output:
        // set Sample, file("${Sample}.sorted.nodup.noM.black.bam"), file("${Sample}.sorted.nodup.noM.black.bam.bai") into bamforsignal
    set Sample, file("${Sample}.nsorted.fixmate.bam") into nsortedbam

    script:
    """
    #!/bin/bash -l
    set -o pipefail
    processbam.sh ${nbam} ${Sample} 8
    """
}


process bam2bed {
    tag "$Sample"
    publishDir  "$results_path/$Sample/$Sample", mode: 'copy'

    input:
    set Sample, file(nsbam) from nsortedbam

    output:
    set Sample, file("${Sample}.nodup.tn5.tagAlign.gz") into finalbedqc
    set Sample, file("${Sample}.nodup.tn5.tagAlign.gz") into finalbed
    set Sample, file("${Sample}.nodup.bedpe.gz") into finalbedpe
    set Sample, file("${Sample}.nodup.tn5.tagAlign.gz"), file("${Sample}.nodup.bedpe.gz") into finalbedmacs

    script:
    """
    convertBAMtoBED.sh ${nsbam}
    cp ${Sample}.tn5.tagAlign.gz  ${Sample}.nodup.tn5.tagAlign.gz
    cp ${Sample}.nsorted.bedpe.gz ${Sample}.nodup.bedpe.gz
    """
        }





process frip {

         publishDir  "$results_path/$sname", mode: 'copy', overwrite: false

         input:
         set sname, file(bed), file(peaks), file(dprefix) from finalbedpe
         file(encodedhs) from encodedhs
    

         output:
         set sname, file("${sname}.frip.txt") into frips

         script:
         """
         getFripQC.py --bed ${bed} --peaks ${encodedhs} --out ${sname}.frip.txt
         """
}





workflow.onComplete {
    def subject = 'pipeline execution'
    def recipient = 'ashley.doane@gmail.com'

    ['mail', '-s', subject, recipient].execute() << """

    Pipeline execution summary
    ---------------------------
    Completed at: ${workflow.complete}
    Duration    : ${workflow.duration}
    Success     : ${workflow.success}
    workDir     : ${workflow.workDir}
    exit status : ${workflow.exitStatus}
    Error report: ${workflow.errorReport ?: '-'}
    """
}
