/*
 * Running statistics using ANCOM-BC, this file will check for differentially abundant taxa
 */

include { QIIME2_FILTERSAMPLES as QIIME2_FILTERSAMPLES_ANCOM } from '../../modules/local/qiime2_filtersamples'
include { QIIME2_ANCOMBC_TAX                 } from '../../modules/local/qiime2_ancombc_tax'
include { QIIME2_ANCOMBC_ASV                 } from '../../modules/local/qiime2_ancombc_asv'

workflow QIIME2_ANCOM {
    take:
    ch_metadata
    ch_asv
    ch_metacolumn_all
    ch_tax
    tax_agglom_min
    tax_agglom_max

    main:
    //Filter ASV table to get rid of samples that have no metadata values
    ch_metadata
        .combine( ch_asv )
        .combine( ch_metacolumn_all )
        .set{ ch_for_filtersamples }
    QIIME2_FILTERSAMPLES_ANCOM ( ch_for_filtersamples )

    //ANCOM on various taxonomic levels
    ch_taxlevel = Channel.of( tax_agglom_min..tax_agglom_max )
    ch_metadata
        .combine( QIIME2_FILTERSAMPLES_ANCOM.out.qza )
        .combine( ch_tax )
        .combine( ch_taxlevel )
        .set{ ch_for_ancom_tax }
    QIIME2_ANCOMBC_TAX ( ch_for_ancom_tax )
    QIIME2_ANCOMBC_TAX.out.ancom.subscribe { if ( it.baseName[0].toString().startsWith("WARNING") ) log.warn it.baseName[0].toString().replace("WARNING ","QIIME2_ANCOMBC_TAX: ") }

    QIIME2_ANCOMBC_ASV ( ch_metadata.combine( QIIME2_FILTERSAMPLES_ANCOM.out.qza.flatten() ) )

    emit:
    ancom = QIIME2_ANCOMBC_ASV.out.ancom.mix(QIIME2_ANCOMBC_TAX.out.ancom)
}
