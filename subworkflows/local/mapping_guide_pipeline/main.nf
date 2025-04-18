nextflow.enable.dsl=2

include { seqSpecParser } from '../../../modules/local/seqSpecParser'
include { createGuideRef } from '../../../modules/local/createGuideRef'
include { mappingGuide } from '../../../modules/local/mappingGuide'
include { anndata_concat } from '../../../modules/local/anndata_concat'

workflow mapping_guide_pipeline {
    take:
    ch_guide
    parsed_covariate_file

    main:
    SeqSpecResult = seqSpecParser(
        file("${params.seqspecs_directory}/${params.Guides_seqspec_yaml}"),
        file(params.seqspecs_directory),
        'guide'
    )

    GuideRef = createGuideRef(file(params.guide_metadata))

    MappingOut = mappingGuide(
        ch_guide,
        GuideRef.guide_index,
        GuideRef.t2g_guide,
        SeqSpecResult.parsed_seqspec,
        SeqSpecResult.barcode_file
    )

    ks_guide_out_dir_collected = MappingOut.ks_guide_out_dir.collect()
    ks_guide_out_dir_collected.view()

    AnndataConcatenate = anndata_concat(
        parsed_covariate_file,
        ks_guide_out_dir_collected
    )

    emit:
    guide_out_dir = MappingOut.ks_guide_out_dir
    ks_guide_out_dir_collected = MappingOut.ks_guide_out_dir.collect()
    concat_anndata_guide = AnndataConcatenate.concat_anndata
}
