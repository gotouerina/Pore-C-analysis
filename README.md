# Pore-C-analysis
Pore-C analysis note


##  01.Align （比对、消化和注释）

I recommand Wf-pore-C(https://github.com/epi2me-labs/wf-pore-c) for align and annotate bam files. Notice that it requires docker.

本人修改过一个优化过运行速度的流程，可以通过以下命令下载：

        wget https://github.com/gotouerina/Pore-C-analysis/releases/download/v1.0/modify-wf-pore-c.tar.gz
        tar -xf https://github.com/gotouerina/Pore-C-analysis/releases/download/v1.0/modify-wf-pore-c.tar.gz        

注意，该流程基于nextflow,需要dcoker支持运行。

    /path/to/nextflow run /path/to/wf-pore-c \
    --fastq  $fq.gz  --ref $fasta --cutter NlaIII  -c increase_memory.config \
    --threads 60 --paired_end_minimum_distance 100 --paired_end_maximum_distance 200 \
    --chunk_size 10000 --paired_end

断点重连：添加--resume参数。断电关机，重连后可用。

If you have no docker, run by add "-profile singularity" parameter 

##  02.Anchor  （基因组挂载）

目前只跑通了yahs(https://github.com/c-zhou/yahs), 1.1版本
（1.2版本使用bam文件会报错，作者没修）

    samtools faidx $fasta
    /path/to/yahs  -e CATG Bathyergus.fasta null.ns.bam  (e接酶切位点，不同酶不同)
    /path/to/juicer pre -a -o out_JBAT yahs.out.bin yahs.out_scaffolds_final.agp  $i.fasta.fai 
    ##这一步会提示下一步命令行是什么，echo 后面的会不一样
    java -Xmx300G -jar juicer_tools_1.22.01.jar  pre --threads 30 out_JBAT.txt out_JBAT.hic <(echo "assembly 1382974809")

将.assemble文件和.hic导入juicebox纠错即可

##  03.Modify

调整挂载结果

        /yahs-1.1/juicer post -o out_JBAT out_JBAT.review.assembly out_JBAT.liftover.agp $fasta
        /yahs-1.1/agp_to_fasta  out_JBAT.liftover.agp $fasta > $fasta.v1.chr.fasta
        python juicer_assembly2agp_fa.py  out_JBAT.review.assembly  $fasta.chr.v1.fasta   $fasta.chr.v2.fasta  28 0 ##28是染色体数量
