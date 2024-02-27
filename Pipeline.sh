## 解包PORE-C流程命令行

# 建立索引 
samtools faidx "reference.fasta"
minimap2 ${minimap_settings} -d "reference.fasta.mmi" "reference.fasta"
gzip -df "${compressed_ref}"


#计算覆盖度
mosdepth --threads $task.cpus --d4 --by "fragments.bed" $args $prefix "concatemers.cs.bam"

##合并sort过的bam
samtools cat --threads $task.cpus -o "${prefix}.${suffix}.bam" --no-PG to_merge/src*.bam
samtools merge --threads $task.cpus -o "${prefix}.bam" -p --write-index --no-PG to_merge/src*.bam

##消化reads
bamindex fetch --chunk=${chunk} "concatemers.bam" |
            pore-c-py digest "${meta.cutter}" --header "concatemers.bam" \
            --threads ${digest_annotate_threads} |
            samtools fastq --threads 1 -T '*' |
            minimap2 -ay -t ${ubam_map_threads} ${minimap2_settings} \
            "reference.fasta.mmi" - |
            pore-c-py annotate - "${meta.alias}" --monomers \
            --threads ${digest_annotate_threads}  --stdout true ${args} | \
            tee "${meta.alias}_out.ns.bam" |
            samtools sort -m 1G --threads ${samtools_threads}  -u --write-index -o "${meta.alias}.cs.bam" -

##bam2pairs
 pairtools parse2  \
    --output-stats "${meta.sample_id}.stats.txt" \
    -c "fasta.fai" --single-end --readid-transform 'readID.split(":")[0]' \
    $args "monomers.mm2.ns.bam" > extract_pairs.tmp
    pairtools restrict  -f "fragments.bed" -o "${meta.sample_id}.pairs.gz" extract_pairs.tmp
    rm -rf extract_pairs.tmp
##pairs合并
pairtools merge -o "${prefix}.pairs.gz" $args 'to_merge/*'
##合并pari信息
pairtools stats -o "${prefix}.pairs.stats.txt" $args to_merge/src*.stats.txt


##pairs格式转hic
 cut -f1,2 fasta.fai > sizes.genome
    pairtools flip input.pairs.gz -c sizes.genome  > flipped.pairs.tmp
    pairtools sort flipped.pairs.tmp > sorted.pairs.tmp
    pairtools dedup sorted.pairs.tmp > dedup.pairs.tmp
    java -jar /home/epi2melabs/juicer_tools_1.22.01.jar pre dedup.pairs.tmp "${meta.sample_id}.hic" sizes.genome
    rm -rf "*.pairs.tmp"


##创建酶切位点
cooler digest -o "fragments.bed" $args "reference.fasta.fai" "reference.fasta"  $enzyme

## pair转cooler
cooler cload pairs -c1 2 -p1 3 -c2 4 -p2 5 $fai:${min_bin_width} $pairs ${pairs.baseName}.cool

##合并mcool文件
cooler merge  ${prefix}.cool $args to_merge/src*.cool
cooler zoomify -r ${resolutions} -o ${prefix}.mcool  ${prefix}.cool


