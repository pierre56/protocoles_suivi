-- Vue d'import spécifique au module comptages_oiseaux_eau pour alimenter la synthèse
-- Inspirée de l'implémentation réalisée pour le module ipamob

DROP VIEW IF EXISTS gn_monitoring.v_synthese_comptages_oiseaux_eau;

CREATE OR REPLACE VIEW gn_monitoring.v_synthese_comptages_oiseaux_eau AS
WITH source AS (
    SELECT id_source
      FROM gn_synthese.t_sources
     WHERE name_source = CONCAT('MONITORING_', UPPER(:'module_code'))
     LIMIT 1
)
SELECT
    o.uuid_observation AS unique_id_sinp,
    v.uuid_base_visit AS unique_id_sinp_grp,
    (SELECT id_source FROM source) AS id_source,
    o.id_observation AS entity_source_pk_value,
    v.id_dataset,
    ref_nomenclatures.get_id_nomenclature('NAT_OBJ_GEO', 'St') AS id_nomenclature_geo_object_nature,
    v.id_nomenclature_grp_typ,
    v.id_nomenclature_tech_collect_campanule,
    NULL::integer AS id_nomenclature_obs_technique,
    NULL::integer AS id_nomenclature_bio_status,
    NULL::integer AS id_nomenclature_bio_condition,
    NULL::integer AS id_nomenclature_naturalness,
    NULL::integer AS id_nomenclature_exist_proof,
    NULL::integer AS id_nomenclature_valid_status,
    NULL::integer AS id_nomenclature_diffusion_level,
    NULL::integer AS id_nomenclature_life_stage,
    NULL::integer AS id_nomenclature_sex,
    ref_nomenclatures.get_id_nomenclature('IND', 'OBJ_DENBR') AS id_nomenclature_obj_count,
    ref_nomenclatures.get_id_nomenclature('TYP_DENBR', 'Es') AS id_nomenclature_type_count,
    NULL::integer AS id_nomenclature_sensitivity,
    ref_nomenclatures.get_id_nomenclature('STATUT_OBS', 'Pr') AS id_nomenclature_observation_status,
    NULL::integer AS id_nomenclature_blurring,
    NULL::integer AS id_nomenclature_behaviour,
    ref_nomenclatures.get_id_nomenclature('STATUT_SOURCE', 'Te') AS id_nomenclature_source_status,
    ref_nomenclatures.get_id_nomenclature('TYP_INF_GEO', '1') AS id_nomenclature_info_geo_type,
    observation_info.nombre_individu AS count_min,
    observation_info.nombre_individu AS count_max,
    o.cd_nom,
    t.nom_complet AS nom_cite,
    alt.altitude_min,
    alt.altitude_max,
    s.geom AS the_geom_4326,
    st_centroid(s.geom) AS the_geom_point,
    s.geom_local AS the_geom_local,
    v.visit_date_min AS date_min,
    COALESCE(v.visit_date_max, v.visit_date_min) AS date_max,
    obs.observers,
    v.id_digitiser,
    NULL::integer AS id_nomenclature_determination_method,
    NULL::date AS meta_validation_date,
    v.meta_create_date,
    v.meta_update_date,
    NULL::text AS last_action,
    v.id_module,
    v.comments AS comment_context,
    o.comments AS comment_description,
    obs.ids_observers,
    tsg.id_sites_group,
    v.id_base_site,
    v.id_base_visit,
    jsonb_build_object(
        'sites_group_name', tsg.sites_group_name,
        'sites_group_code', tsg.sites_group_code,
        'site_name', s.base_site_name,
        'site_code', s.base_site_code,
        'site_dataset_id', site_info.site_dataset_id,
        'site_dataset_name', site_info.site_dataset_name,
        'site_type_site_id', site_info.site_type_site_id,
        'site_type_site_label', site_info.site_type_site_label,
        'visit_dataset_name', visit_dataset.dataset_name,
        'visit_observers_txt', v.observers_txt,
        'visit_if_cmc', visit_info.if_cmc,
        'visit_if_recensement', visit_info.if_recensement,
        'visit_if_comptage_exhaustif', visit_info.if_comptage_exhaustif,
        'visit_if_comptage_condition', visit_info.if_comptage_condition,
        'visit_comm_comptage_condition', visit_info.comm_comptage_condition,
        'visit_if_disturbance', visit_info.if_disturbance,
        'visit_comm_disturbance', visit_info.comm_disturbance,
        'visit_id_nomenclature_disturbance', visit_info.id_nomenclature_disturbance,
        'visit_id_nomenclature_type_comptage', visit_info.id_nomenclature_type_comptage,
        'visit_heure', visit_info.visit_heure,
        'observation_nombre_individu', observation_info.nombre_individu,
        'observation_id_nomenclature_precision_comptage', observation_info.id_nomenclature_precision_comptage,
        'observation_if_cd_nom_exception', observation_info.if_cd_nom_exception,
        'observation_cd_nom_exception', observation_info.cd_nom_exception
    ) AS additional_data
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_observation_complements oc
  ON oc.id_observation = o.id_observation
JOIN gn_monitoring.t_base_visits v
  ON v.id_base_visit = o.id_base_visit
JOIN gn_monitoring.t_base_sites s
  ON s.id_base_site = v.id_base_site
LEFT JOIN gn_monitoring.t_site_complements sc
  ON sc.id_base_site = s.id_base_site
LEFT JOIN gn_monitoring.t_sites_groups tsg
  ON tsg.id_sites_group = sc.id_sites_group
JOIN gn_commons.t_modules m
  ON m.id_module = v.id_module
LEFT JOIN gn_monitoring.t_visit_complements vc
  ON vc.id_base_visit = v.id_base_visit
LEFT JOIN taxonomie.taxref t
  ON t.cd_nom = o.cd_nom
LEFT JOIN LATERAL (
    SELECT
        payload.site_dataset_id,
        site_dataset.dataset_name AS site_dataset_name,
        payload.site_type_site_id,
        ref_nomenclatures.get_nomenclature_label(payload.site_type_site_id, 'fr') AS site_type_site_label
    FROM (
        SELECT
            NULLIF(NULLIF(sc.data::jsonb ->> 'id_dataset', ''), 'null')::integer AS site_dataset_id,
            NULLIF(NULLIF(sc.data::jsonb ->> 'id_nomenclature_type_site', ''), 'null')::integer AS site_type_site_id
    ) payload
    LEFT JOIN gn_meta.t_datasets site_dataset
      ON site_dataset.id_dataset = payload.site_dataset_id
) site_info ON TRUE
LEFT JOIN gn_meta.t_datasets visit_dataset
  ON visit_dataset.id_dataset = v.id_dataset
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_cmc', ''), 'null') AS if_cmc,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_recensement', ''), 'null') AS if_recensement,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_comptage_exhaustif', ''), 'null') AS if_comptage_exhaustif,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_comptage_condition', ''), 'null') AS if_comptage_condition,
        NULLIF(NULLIF(vc.data::jsonb ->> 'comm_comptage_condition', ''), 'null') AS comm_comptage_condition,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_disturbance', ''), 'null') AS if_disturbance,
        NULLIF(NULLIF(vc.data::jsonb ->> 'comm_disturbance', ''), 'null') AS comm_disturbance,
        NULLIF(NULLIF(vc.data::jsonb ->> 'id_nomenclature_disturbance', ''), 'null')::integer AS id_nomenclature_disturbance,
        NULLIF(NULLIF(vc.data::jsonb ->> 'id_nomenclature_type_comptage', ''), 'null')::integer AS id_nomenclature_type_comptage,
        NULLIF(NULLIF(vc.data::jsonb ->> 'visit_heure', ''), 'null') AS visit_heure
) visit_info ON TRUE
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(oc.data::jsonb ->> 'nombre_individu', ''), 'null')::integer AS nombre_individu,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_precision_comptage', ''), 'null')::integer AS id_nomenclature_precision_comptage,
        NULLIF(NULLIF(oc.data::jsonb ->> 'if_cd_nom_exception', ''), 'null') AS if_cd_nom_exception,
        NULLIF(NULLIF(oc.data::jsonb ->> 'cd_nom_exception', ''), 'null') AS cd_nom_exception
) observation_info ON TRUE
LEFT JOIN LATERAL (
    SELECT
        array_agg(r.id_role ORDER BY r.nom_role, r.prenom_role) AS ids_observers,
        string_agg(CONCAT(r.nom_role, ' ', r.prenom_role), ' ; ') AS observers
    FROM gn_monitoring.cor_visit_observer cvo
    JOIN utilisateurs.t_roles r
      ON r.id_role = cvo.id_role
    WHERE cvo.id_base_visit = v.id_base_visit
) obs ON TRUE
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(s.geom_local) alt(altitude_min, altitude_max)
  ON TRUE
WHERE m.module_code = :'module_code';
