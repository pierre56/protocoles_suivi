
-- Vue générique pour alimenter la synthèse dans le cadre d'un protocole site-visite-observation
-- 
-- Ce fichier peut être copié dans le dossier du sous-module et renommé en synthese.sql (et au besoin personnalisé)
-- le fichier sera joué à l'installation avec la valeur de module_code qui sera attribué automatiquement
--
--
-- Personalisations possibles
--
--  - ajouter des champs specifiques qui peuvent alimenter la synthese
--      jointure avec les table de complement
--
--  - choisir les valeurs de champs de nomenclatures qui seront propres au modules


-- ce fichier contient une variable :module_code (ou :'module_code')
-- utiliser psql avec l'option -v module_code=<module_code

-- ne pas remplacer cette variable, elle est indispensable pour les scripts d'installations
-- le module pouvant être installé avec un code différent de l'original

DROP VIEW IF EXISTS gn_monitoring.v_synthese_monitoring;

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_monitoring AS
WITH observation_details AS (
    SELECT od.id_observation,
           jsonb_agg(to_jsonb(od) - 'id_observation') AS observation_details_data
      FROM gn_monitoring.t_observation_details od
     GROUP BY od.id_observation
),
marking_events AS (
    SELECT me.id_individual,
           jsonb_agg(to_jsonb(me) - 'id_individual') AS marking_events_data
      FROM gn_monitoring.t_marking_events me
     GROUP BY me.id_individual
),
site_modules AS (
    SELECT csm.id_base_site,
           jsonb_agg(to_jsonb(csm) - 'id_base_site') AS site_modules_data
      FROM gn_monitoring.cor_site_module csm
     GROUP BY csm.id_base_site
),
site_types AS (
    SELECT cst.id_base_site,
           jsonb_agg(
               jsonb_build_object(
                   'id_type_site', cst.id_type_site,
                   'bib_type_site', to_jsonb(bts)
               )
           ) AS site_types_data
      FROM gn_monitoring.cor_site_type cst
      LEFT JOIN gn_monitoring.bib_type_site bts
        ON bts.id_nomenclature_type_site = cst.id_type_site
     GROUP BY cst.id_base_site
),
site_areas AS (
    SELECT csa.id_base_site,
           jsonb_agg(to_jsonb(csa) - 'id_base_site') AS site_areas_data
      FROM gn_monitoring.cor_site_area csa
     GROUP BY csa.id_base_site
),
site_group_modules AS (
    SELECT csgm.id_sites_group,
           jsonb_agg(to_jsonb(csgm) - 'id_sites_group') AS sites_group_modules_data
      FROM gn_monitoring.cor_sites_group_module csgm
     GROUP BY csgm.id_sites_group
),
visit_observers AS (
    SELECT cvo.id_base_visit,
           jsonb_agg(
               (to_jsonb(cvo) - 'id_base_visit') ||
               jsonb_build_object(
                   'nom_role', r.nom_role,
                   'prenom_role', r.prenom_role
               )
           ) AS visit_observers_data
      FROM gn_monitoring.cor_visit_observer cvo
      LEFT JOIN utilisateurs.t_roles r
        ON r.id_role = cvo.id_role
     GROUP BY cvo.id_base_visit
),
individual_modules AS (
    SELECT cim.id_individual,
           jsonb_agg(to_jsonb(cim) - 'id_individual') AS individual_modules_data
      FROM gn_monitoring.cor_individual_module cim
     GROUP BY cim.id_individual
),
module_types AS (
    SELECT cmt.id_module,
           jsonb_agg(
               jsonb_build_object(
                   'id_type_site', cmt.id_type_site,
                   'bib_type_site', to_jsonb(bts)
               )
           ) AS module_types_data
      FROM gn_monitoring.cor_module_type cmt
      LEFT JOIN gn_monitoring.bib_type_site bts
        ON bts.id_nomenclature_type_site = cmt.id_type_site
     GROUP BY cmt.id_module
),
SELECT
    v.id_module,
    mc.uuid_module_complement,
    mc.id_list_observer,
    mc.id_list_taxonomy,
    mc.b_synthese,
    mc.taxonomy_display_field_name,
    mc.b_draw_sites_group,
    mc.data AS module_complements_data,
    mc.cd_nom AS module_cd_nom,
    mt.module_types_data,
    sg.id_sites_group,
    sg.sites_group_name,
    sg.sites_group_code,
    sg.sites_group_description,
    sg.uuid_sites_group,
    sg.comments AS sites_group_comments,
    sg.data AS sites_group_data,
    sg.meta_create_date AS sites_group_create_date,
    sg.meta_update_date AS sites_group_update_date,
    sg.id_digitiser AS sites_group_id_digitiser,
    sg.geom AS sites_group_geom,
    sg.geom_local AS sites_group_geom_local,
    sg.altitude_min AS sites_group_altitude_min,
    sg.altitude_max AS sites_group_altitude_max,
    sgm.sites_group_modules_data,
    bs.id_base_site,
    bs.uuid_base_site,
    bs.base_site_name,
    bs.base_site_description,
    bs.base_site_code,
    bs.first_use_date,
    bs.id_inventor,
    bs.id_digitiser AS site_id_digitiser,
    bs.geom,
    bs.geom_local,
    bs.altitude_min,
    bs.altitude_max,
    bs.meta_create_date AS site_create_date,
    bs.meta_update_date AS site_update_date,
    sc.data AS site_complements_data,
    sm.site_modules_data,
    st.site_types_data,
    sa.site_areas_data,
    v.id_base_visit,
    v.uuid_base_visit,
    v.id_dataset,
    v.id_digitiser AS visit_id_digitiser,
    v.visit_date_min,
    v.visit_date_max,
    v.id_nomenclature_tech_collect_campanule,
    v.id_nomenclature_grp_typ,
    v.comments AS visit_comments,
    v.meta_create_date AS visit_create_date,
    v.meta_update_date AS visit_update_date,
    v.observers_txt,
    vc.data AS visit_complements_data,
    vo.visit_observers_data,
    o.id_observation,
    o.uuid_observation,
    o.cd_nom,
    o.comments AS observation_comments,
    o.id_digitiser AS observation_id_digitiser,
    o.id_individual,
    oc.data AS observation_complements_data,
    od.observation_details_data,
    ind.uuid_individual,
    ind.individual_name,
    ind.cd_nom AS individual_cd_nom,
    ind.id_nomenclature_sex AS individual_id_nomenclature_sex,
    ind.active AS individual_active,
    ind.comment AS individual_comment,
    ind.id_digitiser AS individual_id_digitiser,
    ind.meta_create_date AS individual_create_date,
    ind.meta_update_date AS individual_update_date,
    im.individual_modules_data,
    me.marking_events_data
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_base_visits v
  ON v.id_base_visit = o.id_base_visit
LEFT JOIN gn_monitoring.t_base_sites bs
  ON bs.id_base_site = v.id_base_site
LEFT JOIN gn_monitoring.t_site_complements sc
  ON sc.id_base_site = bs.id_base_site
LEFT JOIN gn_monitoring.t_sites_groups sg
  ON sg.id_sites_group = sc.id_sites_group
LEFT JOIN gn_monitoring.t_visit_complements vc
  ON vc.id_base_visit = v.id_base_visit
LEFT JOIN gn_monitoring.t_observation_complements oc
  ON oc.id_observation = o.id_observation
LEFT JOIN observation_details od
  ON od.id_observation = o.id_observation
LEFT JOIN gn_monitoring.t_individuals ind
  ON ind.id_individual = o.id_individual
LEFT JOIN gn_monitoring.t_module_complements mc
  ON mc.id_module = v.id_module
LEFT JOIN marking_events me
  ON me.id_individual = o.id_individual
LEFT JOIN site_modules sm
  ON sm.id_base_site = v.id_base_site
LEFT JOIN site_types st
  ON st.id_base_site = v.id_base_site
LEFT JOIN site_areas sa
  ON sa.id_base_site = v.id_base_site
LEFT JOIN site_group_modules sgm
  ON sgm.id_sites_group = sc.id_sites_group
LEFT JOIN visit_observers vo
  ON vo.id_base_visit = v.id_base_visit
LEFT JOIN individual_modules im
  ON im.id_individual = o.id_individual
LEFT JOIN module_types mt
  ON mt.id_module = v.id_module;

DROP VIEW IF EXISTS gn_monitoring.v_synthese_:module_code;

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_:module_code
AS WITH source AS (
         SELECT id_source
           FROM gn_synthese.t_sources
          WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
        )
 SELECT 
 	o.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    (SELECT id_source FROM source) AS id_source,
    o.id_observation AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '20'::character varying) AS id_nomenclature_obs_meth, 
    nullif(json_extract_path(oc.data::json,'id_nomenclature_stade')::text,'null')::integer AS id_nomenclature_life_stage,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_sex')::text,'null')::integer AS id_nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('ETAT_BIO'::character varying, '1'::character varying) as id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    nullif(((oc.data::json #> '{count_min}'::text[])::text),'null')::integer AS count_min,
    nullif(((oc.data::json #> '{count_max}'::text[])::text),'null')::integer AS count_max,
    o.id_observation,
    o.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    v.visit_date_min AS date_max,
    obs.observers,
    v.id_digitiser,
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN'::character varying, '1'::character varying) AS id_nomenclature_determination_method,
    v.id_module as id_module,
    v.comments AS comment_context,
    o.comments AS comment_description,
    obs.ids_observers,
    v.id_base_site,
    v.id_base_visit, 
    json_build_object(
      'aire_etude', tsg.sites_group_name,
      'nom_site', s.base_site_name,
      'milieu_aquatique', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'milieu_aquatique')::text,'null')::integer, 'fr'),
      'variation_eau', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'variation_eau')::text,'null')::integer, 'fr'),
      'courant',  ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'courant')::text,'null')::integer, 'fr'),
    	'num_passage', json_extract_path(vc.data::json,'num_passage')::text, 
    	'accessibilite', (vc.data::json #> '{accessibility}'::text[]),
    	'pluviosite', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'pluviosite')::text,'null')::integer, 'fr'),
    	'couverture_nuageuse', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'couverture_nuageuse')::text,'null')::integer, 'fr'),
    	'vent', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vent')::text,'null')::integer, 'fr'),
    	'turbidite', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'turbidite')::text,'null')::integer, 'fr'),
    	'vegetation_aquatique_principale', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vegetation_aquatique_principale')::text,'null')::integer, 'fr'),
    	'rives', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'rives')::text,'null')::integer, 'fr'),
    	'habitat_terrestre_environnant', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'habitat_terrestre_environnant')::text,'null')::integer, 'fr'),
    	'activite_humaine', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'activite_humaine')::text,'null')::integer, 'fr')
    	) as additional_data
   FROM gn_monitoring.t_base_visits v
   	 JOIN gn_monitoring.t_visit_complements vc on v.id_base_visit = vc.id_base_visit 
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_monitoring.t_site_complements sc on sc.id_base_site = s.id_base_site
     JOIN gn_monitoring.t_sites_groups tsg ON sc.id_sites_group = tsg.id_sites_group
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
     LEFT JOIN LATERAL ( SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
    WHERE m.module_code = :'module_code';

drop VIEW if exists  gn_monitoring.v_synthese_ipamob_v2 ;
CREATE OR REPLACE VIEW gn_monitoring.v_synthese_ipamob_v2
AS WITH source AS (
         SELECT id_source
           FROM gn_synthese.t_sources
          WHERE name_source = CONCAT('MONITORING_', UPPER('ipamob'))
        )
 SELECT 
 	o.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    (SELECT id_source FROM source) AS id_source,
    o.id_observation AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('METH_OBS'::character varying, '20'::character varying) AS id_nomenclature_obs_meth, 
    nullif(json_extract_path(oc.data::json,'id_nomenclature_stade')::text,'null')::integer AS id_nomenclature_life_stage,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_sex')::text,'null')::integer AS id_nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('OBJ_DENBR'::character varying, 'IND'::character varying) AS id_nomenclature_obj_count,
    nullif(json_extract_path(oc.data::json,'id_nomenclature_typ_denbr')::text, 'null')::integer AS id_nomenclature_type_count,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS'::character varying, 'Pr'::character varying) AS id_nomenclature_observation_status,
    ref_nomenclatures.get_id_nomenclature('ETAT_BIO'::character varying, '1'::character varying) as id_nomenclature_bio_condition,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE'::character varying, 'Te'::character varying) AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO'::character varying, '1'::character varying) AS id_nomenclature_info_geo_type,
    nullif(((oc.data::json #> '{count}'::text[])::text),'null')::integer AS count_min,
    nullif(((oc.data::json #> '{count}'::text[])::text),'null')::integer AS count_max,
    o.id_observation,
    o.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    v.visit_date_min AS date_max,
    obs.observers,
    v.id_digitiser,
    ref_nomenclatures.get_id_nomenclature('METH_DETERMIN'::character varying, '1'::character varying) AS id_nomenclature_determination_method,
    v.id_module as id_module,
    v.comments AS comment_context,
    o.comments AS comment_description,
    obs.ids_observers,
    tsg.id_sites_group,
    v.id_base_site,
    v.id_base_visit, 
    json_build_object(
      'aire_etude', tsg.sites_group_name,
      'nom_site', s.base_site_name,
      'habitat_transect', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'radio_habitat')::text,'null')::integer, 'fr'),
      'type_protection', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'id_nomenclature_type_protection')::text,'null')::integer, 'fr'),
      'courant',  ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(sc.data::json,'courant')::text,'null')::integer, 'fr'),
    	'num_passage', json_extract_path(vc.data::json,'num_passage')::text, 
    	'accessibilite', (vc.data::json #> '{accessibility}'::text[]),
    	'pluviosite', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'pluviosite')::text,'null')::integer, 'fr'),
    	'couverture_nuageuse', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'couverture_nuageuse')::text,'null')::integer, 'fr'),
    	'vent', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vent')::text,'null')::integer, 'fr'),
    	'turbidite', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'turbidite')::text,'null')::integer, 'fr'),
    	'vegetation_aquatique_principale', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'vegetation_aquatique_principale')::text,'null')::integer, 'fr'),
    	'rives', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'rives')::text,'null')::integer, 'fr'),
    	'habitat_terrestre_environnant', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'habitat_terrestre_environnant')::text,'null')::integer, 'fr'),
    	'activite_humaine', ref_nomenclatures.get_nomenclature_label(nullif(json_extract_path(vc.data::json,'activite_humaine')::text,'null')::integer, 'fr')
    	) as additional_data
   FROM gn_monitoring.t_base_visits v
   	 JOIN gn_monitoring.t_visit_complements vc on v.id_base_visit = vc.id_base_visit 
     JOIN gn_monitoring.t_base_sites s ON s.id_base_site = v.id_base_site
     JOIN gn_monitoring.t_site_complements sc on sc.id_base_site = s.id_base_site
     JOIN gn_monitoring.t_sites_groups tsg ON sc.id_sites_group = tsg.id_sites_group
     JOIN gn_commons.t_modules m ON m.id_module = v.id_module
     JOIN gn_monitoring.t_observations o ON o.id_base_visit = v.id_base_visit
     JOIN gn_monitoring.t_observation_complements oc ON oc.id_observation = o.id_observation
     JOIN taxonomie.taxref t ON t.cd_nom = o.cd_nom
     LEFT JOIN LATERAL ( SELECT array_agg(r.id_role) AS ids_observers,
            string_agg(concat(r.nom_role, ' ', r.prenom_role), ' ; '::text) AS observers
           FROM gn_monitoring.cor_visit_observer cvo
             JOIN utilisateurs.t_roles r ON r.id_role = cvo.id_role
          WHERE cvo.id_base_visit = v.id_base_visit) obs ON true
     LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max) ON true
    WHERE m.module_code = 'ipamob';
