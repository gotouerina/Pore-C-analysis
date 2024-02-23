# Pore-C-analysis
Pore-C analysis note


##  01.Align （比对、消化和注释）

I recommand Wf-pore-C(https://github.com/epi2me-labs/wf-pore-c) for align and annotate bam files. Notice that it requires docker.

注意，该流程基于nextflow,需要dcoker支持运行。

    /path/to/nextflow run /path/to/wf-pore-c \
    --fastq  $fq.gz  --ref $fasta --cutter NlaIII  -c increase_memory.config \
    --threads 60 --paired_end_minimum_distance 100 --paired_end_maximum_distance 200 \
    --chunk_size 10000 --paired_end

断点重连：添加--resume参数。断电关机，重连后可用。

##  02.Anchor  （基因组挂载）

目前只跑通了yahs(https://github.com/c-zhou/yahs), 1.1版本
（1.2版本使用bam文件会报错，作者没修）

    samtools faidx $fasta
    /path/to/yahs  -e CATG Bathyergus.fasta null.ns.bam  (e接酶切位点，不同酶不同)
    /path/to/juicer pre -a -o out_JBAT yahs.out.bin yahs.out_scaffolds_final.agp  $i.fasta.fai 这一步会提示下一步命令行是什么，echo 后面的会不一样
    java -Xmx36G -jar juicer_tools_1.22.01.jar  pre --threads 30 out_JBAT.txt out_JBAT.hic <(echo "assembly 1382974809")

将.assemble文件和.hic导入juicebox纠错即可
    
