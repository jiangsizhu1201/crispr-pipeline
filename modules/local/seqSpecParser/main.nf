
process seqSpecParser {
  cache 'lenient'

  input:
    path seqSpec_yaml
    path directory
    val modalities

  output:
    path "${modalities}_parsed_seqSpec.txt", emit: parsed_seqspec
    path "barcode_file.txt", emit: barcode_file

  script:
    """
    parsing_guide_metadata.py --modalities ${modalities} --yaml_file ${seqSpec_yaml} --directory ${directory} --output_file ${modalities}_parsed_seqSpec.txt
    barcode_file=\$(awk 'NR==2 {print \$3}' ${modalities}_parsed_seqSpec.txt)
    echo "The full path to the renamed barcode file: ${directory}/\${barcode_file}"
    cp "${directory}/\${barcode_file}" barcode_file.txt
    """
}
