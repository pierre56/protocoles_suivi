----- COMPTAGES OISEAUX D'EAU -----
-- View: gn_monitoring.v_export_comptages_oiseaux_eau_standard
-- Export standard des observations avec l'ensemble des attributs utiles au protocole

DROP VIEW IF EXISTS gn_monitoring.v_export_comptages_oiseaux_eau_standard;

CREATE OR REPLACE VIEW gn_monitoring.v_export_comptages_oiseaux_eau_standard AS
SELECT
    /* MODULE */
    m.module_code,
    v.id_module,

    /* SITES GROUP */
    tsg.id_sites_group,
    tsg.sites_group_name,
    tsg.sites_group_code,
    tsg.sites_group_description,
    tsg.uuid_sites_group,
    tsg.comments AS sites_group_comments,
    tsg.meta_create_date AS sites_group_create_date,
    tsg.meta_update_date AS sites_group_update_date,
    tsg.id_digitiser AS sites_group_id_digitiser,
    st_astext(tsg.geom) AS geom_sites_group_wkt,
    st_astext(tsg.geom_local) AS geom_local_sites_group_wkt,
    st_asgeojson(tsg.geom) AS geom_sites_group_geojson,
    st_asgeojson(tsg.geom_local) AS geom_local_sites_group_geojson,
    tsg.altitude_min AS sites_group_altitude_min,
    tsg.altitude_max AS sites_group_altitude_max,

    /* SITE */
    bs.id_base_site,
    bs.uuid_base_site,
    bs.base_site_name,
    bs.base_site_description,
    bs.base_site_code,
    bs.first_use_date,
    bs.id_inventor,
    bs.id_digitiser AS site_id_digitiser,
    st_astext(bs.geom) AS geom_wkt,
    st_astext(bs.geom_local) AS geom_local_wkt,
    st_asgeojson(bs.geom) AS geom_geojson,
    st_asgeojson(bs.geom_local) AS geom_local_geojson,
    bs.altitude_min,
    bs.altitude_max,
    bs.meta_create_date AS site_create_date,
    bs.meta_update_date AS site_update_date,
    site_info.site_dataset_id,
    site_info.site_dataset_name,
    site_info.site_type_site_id,
    site_info.site_type_site_label,
    alt.altitude_min AS altitude_intersection_min,
    alt.altitude_max AS altitude_intersection_max,

    /* VISIT */
    v.id_base_visit,
    v.uuid_base_visit,
    v.id_dataset,
    visit_dataset.dataset_name,
    v.id_digitiser AS visit_id_digitiser,
    v.visit_date_min,
    v.visit_date_max,
    v.id_nomenclature_tech_collect_campanule,
    visit_nomenclatures.visit_tech_collect_label,
    v.id_nomenclature_grp_typ,
    visit_nomenclatures.visit_grp_typ_label,
    v.comments AS visit_comments,
    v.meta_create_date AS visit_create_date,
    v.meta_update_date AS visit_update_date,
    v.observers_txt,

    /* VISIT COMPLEMENTS */
    visit_complements.visit_if_cmc,
    visit_complements.visit_if_recensement,
    visit_complements.visit_if_comptage_exhaustif,
    visit_complements.visit_if_comptage_condition,
    visit_complements.visit_comm_comptage_condition,
    visit_complements.visit_if_disturbance,
    visit_complements.visit_comm_disturbance,
    visit_complements.visit_id_nomenclature_disturbance,
    visit_complements.visit_disturbance_label,
    visit_complements.visit_id_nomenclature_type_comptage,
    visit_complements.visit_type_comptage_label,
    visit_complements.visit_heure,

    /* OBSERVERS */
    visit_observers.observer_ids,
    visit_observers.observer_names,
    visit_observers.organismes_rattaches,

    /* OBSERVATION */
    o.id_observation,
    o.uuid_observation,
    o.cd_nom,
    t.lb_nom,
    t.nom_vern,
    o.comments AS observation_comments,
    o.id_digitiser AS observation_id_digitiser,

    /* OBSERVATION COMPLEMENTS */
    observation_complements.observation_nombre_individu,
    observation_complements.observation_id_nomenclature_precision_comptage,
    observation_complements.observation_precision_label,
    observation_complements.observation_if_cd_nom_exception,
    observation_complements.observation_cd_nom_exception
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_base_visits v
  ON v.id_base_visit = o.id_base_visit
JOIN gn_commons.t_modules m
  ON m.id_module = v.id_module
LEFT JOIN gn_monitoring.t_observation_complements oc
  ON oc.id_observation = o.id_observation
LEFT JOIN gn_monitoring.t_base_sites bs
  ON bs.id_base_site = v.id_base_site
LEFT JOIN gn_monitoring.t_site_complements sc
  ON sc.id_base_site = bs.id_base_site
LEFT JOIN gn_monitoring.t_sites_groups tsg
  ON tsg.id_sites_group = sc.id_sites_group
LEFT JOIN gn_meta.t_datasets visit_dataset
  ON visit_dataset.id_dataset = v.id_dataset
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
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_cmc', ''), 'null') AS visit_if_cmc,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_recensement', ''), 'null') AS visit_if_recensement,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_comptage_exhaustif', ''), 'null') AS visit_if_comptage_exhaustif,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_comptage_condition', ''), 'null') AS visit_if_comptage_condition,
        NULLIF(NULLIF(vc.data::jsonb ->> 'comm_comptage_condition', ''), 'null') AS visit_comm_comptage_condition,
        NULLIF(NULLIF(vc.data::jsonb ->> 'if_disturbance', ''), 'null') AS visit_if_disturbance,
        NULLIF(NULLIF(vc.data::jsonb ->> 'comm_disturbance', ''), 'null') AS visit_comm_disturbance,
        NULLIF(NULLIF(vc.data::jsonb ->> 'id_nomenclature_disturbance', ''), 'null')::integer AS visit_id_nomenclature_disturbance,
        ref_nomenclatures.get_nomenclature_label(
            NULLIF(NULLIF(vc.data::jsonb ->> 'id_nomenclature_disturbance', ''), 'null')::integer,
            'fr'
        ) AS visit_disturbance_label,
        NULLIF(NULLIF(vc.data::jsonb ->> 'id_nomenclature_type_comptage', ''), 'null')::integer AS visit_id_nomenclature_type_comptage,
        ref_nomenclatures.get_nomenclature_label(
            NULLIF(NULLIF(vc.data::jsonb ->> 'id_nomenclature_type_comptage', ''), 'null')::integer,
            'fr'
        ) AS visit_type_comptage_label,
        NULLIF(NULLIF(vc.data::jsonb ->> 'visit_heure', ''), 'null') AS visit_heure
) visit_complements ON TRUE
LEFT JOIN LATERAL (
    SELECT
        ref_nomenclatures.get_nomenclature_label(v.id_nomenclature_tech_collect_campanule, 'fr') AS visit_tech_collect_label,
        ref_nomenclatures.get_nomenclature_label(v.id_nomenclature_grp_typ, 'fr') AS visit_grp_typ_label
) visit_nomenclatures ON TRUE
LEFT JOIN LATERAL (
    SELECT
        array_agg(cvo.id_role ORDER BY r.nom_role, r.prenom_role) AS observer_ids,
        string_agg(DISTINCT concat_ws(' ', r.nom_role, r.prenom_role), ' ; ') AS observer_names,
        string_agg(DISTINCT org.nom_organisme, ' ; ') AS organismes_rattaches
    FROM gn_monitoring.cor_visit_observer cvo
    LEFT JOIN utilisateurs.t_roles r
      ON r.id_role = cvo.id_role
    LEFT JOIN utilisateurs.bib_organismes org
      ON org.id_organisme = r.id_organisme
    WHERE cvo.id_base_visit = v.id_base_visit
) visit_observers ON TRUE
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(oc.data::jsonb ->> 'nombre_individu', ''), 'null')::integer AS observation_nombre_individu,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_precision_comptage', ''), 'null')::integer AS observation_id_nomenclature_precision_comptage,
        ref_nomenclatures.get_nomenclature_label(
            NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_precision_comptage', ''), 'null')::integer,
            'fr'
        ) AS observation_precision_label,
        NULLIF(NULLIF(oc.data::jsonb ->> 'if_cd_nom_exception', ''), 'null') AS observation_if_cd_nom_exception,
        NULLIF(NULLIF(oc.data::jsonb ->> 'cd_nom_exception', ''), 'null') AS observation_cd_nom_exception
) observation_complements ON TRUE
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(bs.geom_local) alt(altitude_min, altitude_max)
  ON TRUE
WHERE m.module_code = 'comptages_oiseaux_eau';

GRANT SELECT ON TABLE gn_monitoring.v_export_comptages_oiseaux_eau_standard TO geonatadmin;
