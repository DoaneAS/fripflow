#!/bin/bash

# read from command line the unfiltered and unsortde bam file

p1=$1
pname=$2
MYSLOTS=$3
NSLOTS="8"

if [ -z "${NSLOTS}+x"  ] ; then
    NSLOTS="${MYSLOTS}"
fi


. ~/spackloads.sh

#BLACK="/home/asd2007/melnick_bcell_scratch/asd2007/Reference/encodeBlack.bed"
# help
if [ -z "$p1"  ]
then
    echo "This will sort bam, remove mitochondria/duplicates and histogram insert size"
    echo "$(basename $0) <bamFile>"
    echo "<samFile>: Required bam input file"
    exit
fi



spack load jdk
spack load samtools
spack load bedtools2

#export R_JAVA_LD_LIBRARY_PATH=${JAVA_HOME}/jre/lib/amd64/server
#export PATH="/home/asd2007/Tools/bedtools2/bin:$PATH"

export PICARD="/home/asd2007/Tools/picard/build/libs/picard.jar"

export PATH="/home/asd2007/Tools/picard/build/libs:$PATH"

#export PATH=$JAVA_HOME/bin:$PATH

#alias picard="java -Xms500m -Xmx3G -jar $PICARD"

#export PATH="/athena/elementolab/scratch/asd2007/Tools/homer/bin:$PATH"
echo "Sorting..."
out1prefix=$(echo $pname )
out1="${out1prefix}.nsort.bam"
echo ${out1}
#samtools view -u -q 30 Sample_Ly7_pooled_500k.bam | sambamba sort --memory-limit 32GB --nthreads 6 /dev/stdin --out Sample_Ly7_pooled_500k.sorted.bam
    # echo "aligning : $TMPDIR/${Sample}.R1.trim.fq ,  $TMPDIR/${Sample}.R2.trim.fq using bwa-mem.."
    # bwa mem -t ${NSLOTS} -M $TMPDIR/BWAIndex/genome.fa $TMPDIR/${Sample}.R1.trim.fastq $TMPDIR/${Sample}.R2.trim.fastq | samtools view -bS - >  $TMPDIR/${Sample}.bam
#fi



samtools index $p1

#samtools rmdup


#samtools idxstats $out2 | cut -f 1 | grep -v chrM | xargs samtools view -b $out2 > $out2m


#something odd happening
#bedtools subtract -A -a $out2m -b $BLACK > $out2mb
# Remove multimapping and improper reads

#samtools view -@ 6 -F 1804 -f 2 -u ${out2m} > ${out3}







## make bam with marked dups and generate PBC file for QC
## BELOW for QC only

echo "Namesort ..."

sambamba sort -n -u --memory-limit 32GB \
         --nthreads ${NSLOTS} --tmpdir ${TMPDIR} --out ${out1prefix}.nsort.bam $p1

#samtools sort -n $p1 -o ${out1prefix}.nsort.bam

#sambamba sort --memory-limit 30GB \
#         --nthreads ${NSLOTS} --tmpdir ${TMPDIR} --out ${TMPDIR}/${Sample}/${Sample}.bam ${TMPDIR}/${Sample}/${Sample}.bam

samtools fixmate -r ${out1prefix}.nsort.bam ${out1prefix}.nsorted.fixmate.bam
#samtools view -F 1804 -f 2 -u  ${out1prefix}.nsort.fixmate.bam | samtools sort - > ${out1prefix}.filt.srt.bam




