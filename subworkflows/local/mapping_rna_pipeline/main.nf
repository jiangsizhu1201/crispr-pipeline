nextflow.enable.dsl=2

include { seqSpecParser } from '../../../modules/local/seqSpecParser'
include { downloadReference } from '../../../modules/local/downloadReference'
include { mappingscRNA } from '../../../modules/local/mappingscRNA'
include { anndata_concat } from '../../../modules/local/anndata_concat'

workflow mapping_rna_pipeline {
    take:
    ch_rna
    parsed_covariate_file  // file: parsed covariate file from prepare_mapping_pipeline

    main:
    SeqSpecResult = seqSpecParser(
        file("${params.seqspecs_directory}/${params.scRNA_seqspec_yaml}"),
        file(params.seqspecs_directory),
        'rna'
    )

    DownloadRefResult = downloadReference(params.transcriptome)

    MappingOut = mappingscRNA(
        ch_rna,
        DownloadRefResult.transcriptome_idx,
        DownloadRefResult.t2g_transcriptome_index,
        SeqSpecResult.parsed_seqspec,
        SeqSpecResult.barcode_file
    )

    ks_transcripts_out_dir_collected = MappingOut.ks_transcripts_out_dir.collect()
    ks_transcripts_out_dir_collected.view()

    AnndataConcatenate = anndata_concat(
        parsed_covariate_file,
        ks_transcripts_out_dir_collected
    )

    emit:
    trans_out_dir = MappingOut.ks_transcripts_out_dir
    ks_transcripts_out_dir_collected = MappingOut.ks_transcripts_out_dir.collect()
    concat_anndata_rna = AnndataConcatenate.concat_anndata
}
