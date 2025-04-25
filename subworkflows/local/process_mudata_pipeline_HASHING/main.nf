
nextflow.enable.dsl=2

include { PreprocessAnnData } from '../../../modules/local/PreprocessAnnData'
include { CreateMuData_HASHING } from '../../../modules/local/CreateMuData_HASHING'
include { demultiplex } from '../../../modules/local/demultiplex'
include { filter_hashing } from '../../../modules/local/filter_hashing'
include { hashing_concat } from '../../../modules/local/hashing_concat'
include { prepare_assignment } from '../../../modules/local/prepare_assignment'
include { mudata_concat } from '../../../modules/local/mudata_concat'
include { guide_assignment_cleanser } from '../../../modules/local/guide_assignment_cleanser'
include { guide_assignment_sceptre } from '../../../modules/local/guide_assignment_sceptre'
include { skipGTFDownload } from '../../../modules/local/skipGTFDownload'
include { downloadGTF } from '../../../modules/local/downloadGTF'
include { prepare_guide_inference } from '../../../modules/local/prepare_guide_inference'
include { prepare_all_guide_inference } from '../../../modules/local/prepare_all_guide_inference'
include { prepare_user_guide_inference } from '../../../modules/local/prepare_user_guide_inference'
include { inference_sceptre } from '../../../modules/local/inference_sceptre'
include { inference_perturbo } from '../../../modules/local/inference_perturbo'
include { inference_mudata } from '../../../modules/local/inference_mudata'
include { mergedResults } from '../../../modules/local/mergedResults'

workflow process_mudata_pipeline_HASHING {

    take:
    concat_anndata_rna
    trans_out_dir
    concat_anndata_guide
    guide_out_dir
    concat_anndata_hashing
    hashing_out_dir
    covariate_string

    main:

    Preprocessed_AnnData = PreprocessAnnData(
        concat_anndata_rna,
        trans_out_dir.flatten().first(),
        params.min_genes,
        params.min_cells,
        params.pct_mito,
        params.transcriptome
        )

    Hashing_Filtered = filter_hashing(
        Preprocessed_AnnData.filtered_anndata_rna,
        concat_anndata_hashing
        )

    Demultiplex = demultiplex(Hashing_Filtered.hashing_filtered_anndata.flatten())

    hashing_demux_anndata_collected =Demultiplex.hashing_demux_anndata.collect()
    hashing_demux_anndata_collected.view()

    hashing_demux_unfiltered_anndata_collected =Demultiplex.hashing_demux_unfiltered_anndata.collect()
    hashing_demux_unfiltered_anndata_collected.view()

    Hashing_Concat = hashing_concat(hashing_demux_anndata_collected, hashing_demux_unfiltered_anndata_collected)

    if (file(params.gtf_local_path).exists()) {
        GTF_Reference = skipGTFDownload(file(params.gtf_local_path))
    }
    else {
        GTF_Reference = downloadGTF(params.gtf_download_path)
    }

    println "filtered_anndata_rna: ${Preprocessed_AnnData.filtered_anndata_rna}"
    println "concatenated_hashing_demux: ${Hashing_Concat.concatenated_hashing_demux}"
    println "gencode_gtf: ${GTF_Reference.gencode_gtf}"

    MuData = CreateMuData_HASHING(
        Preprocessed_AnnData.filtered_anndata_rna,
        concat_anndata_guide,
        Hashing_Concat.concatenated_hashing_demux,
        file(params.guide_metadata),
        GTF_Reference.gencode_gtf,
        params.moi,
        params.capture_method
        )

    Prepare_assignment = prepare_assignment{MuData.mudata}

    if (params.assignment_method == "cleanser") {
        Guide_Assignment = guide_assignment_cleanser(Prepare_assignment.prepare_assignment_mudata.flatten(), params.THRESHOLD)
        guide_assignment_collected =  Guide_Assignment.guide_assignment_mudata_output.collect()
        Mudata_concat = mudata_concat(guide_assignment_collected)
        }

    else if (params.assignment_method == "sceptre") {
        Guide_Assignment = guide_assignment_sceptre(Prepare_assignment.prepare_assignment_mudata.flatten())
        guide_assignment_collected =  Guide_Assignment.guide_assignment_mudata_output.collect()
        Mudata_concat = mudata_concat(guide_assignment_collected)
        }

    if (params.inference_option == 'predefined_pairs') {
        PrepareInference = prepare_user_guide_inference(
            Mudata_concat.concat_mudata,
            file(params.user_inference)
        )}
    else if (params.inference_option == 'by_distance') {
        PrepareInference = prepare_guide_inference(
            Mudata_concat.concat_mudata,
            GTF_Reference.gencode_gtf,
            params.distance_from_center
        )}
    else if (params.inference_option == 'all_by_all') {
        PrepareInference = prepare_all_guide_inference(
            Mudata_concat.concat_mudata,
            GTF_Reference.gencode_gtf
        )}

    if (params.inference_method == "sceptre"){
        TestResults = inference_sceptre(PrepareInference.mudata_inference_input, covariate_string)
        GuideInference = inference_mudata(TestResults.test_results, PrepareInference.mudata_inference_input, params.inference_method)
    }
    else if (params.inference_method == "perturbo"){
        GuideInference = inference_perturbo(PrepareInference.mudata_inference_input, params.inference_method)
    }
    else if (params.inference_method == "sceptre,perturbo") {
        SceptreResults = inference_sceptre(PrepareInference.mudata_inference_input, covariate_string)
        PerturboResults = inference_perturbo(PrepareInference.mudata_inference_input,  "perturbo")
        GuideInference = mergedResults(SceptreResults.test_results, PerturboResults.inference_mudata)
    }

    emit:
    inference_mudata = GuideInference.inference_mudata
    gencode_gtf = GTF_Reference.gencode_gtf
    figures_dir = Preprocessed_AnnData.figures_dir
    adata_rna = Preprocessed_AnnData.adata_rna
    filtered_anndata_rna = Preprocessed_AnnData.filtered_anndata_rna
    adata_guide = MuData.adata_guide
    adata_hashing = Hashing_Filtered.adata_hashing
    adata_demux = Hashing_Concat.concatenated_hashing_demux
    adata_unfiltered_demux = Hashing_Concat.concatenated_hashing_unfiltered_demux
}
