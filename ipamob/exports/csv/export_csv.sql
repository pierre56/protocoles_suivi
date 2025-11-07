DROP VIEW IF EXISTS gn_monitoring.v_export_ipamob;

CREATE OR REPLACE VIEW gn_monitoring.v_export_ipamob AS
SELECT
    m.module_code,
    v.id_module,
    mc.uuid_module_complement,
    mc.id_list_observer,
    mc.id_list_taxonomy,
    mc.b_synthese,
    mc.taxonomy_display_field_name,
    mc.b_draw_sites_group,
    module_type_data.module_type_site_ids,
    module_type_data.module_type_nomenclature_ids,
    -- module_type_data.module_type_configs,
    sg.id_sites_group,
    sg.sites_group_name,
    sg.sites_group_code,
    sg.sites_group_description,
    sg.uuid_sites_group,
    sg.comments AS sites_group_comments,
    sg.meta_create_date AS sites_group_create_date,
    sg.meta_update_date AS sites_group_update_date,
    sg.id_digitiser AS sites_group_id_digitiser,
    sg.geom AS sites_group_geom,
    sg.geom_local AS sites_group_geom_local,
    sg.altitude_min AS sites_group_altitude_min,
    sg.altitude_max AS sites_group_altitude_max,
    sites_group_info.sites_group_commune AS sites_group_commune,
    sites_group_info.sites_group_id_inventor,
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
    alt.altitude_min AS altitude_intersection_min,
    alt.altitude_max AS altitude_intersection_max,
    site_complements.site_radio_habitat,
    site_complements.site_id_nomenclature_type_protection,
    site_type_data.site_type_site_ids,
    site_type_data.site_type_nomenclature_ids,
    -- site_type_data.site_type_configs,
    site_area_data.site_area_ids,
    v.id_base_visit,
    v.uuid_base_visit,
    v.id_dataset,
    d.dataset_name,
    v.id_digitiser AS visit_id_digitiser,
    v.visit_date_min,
    v.visit_date_max,
    v.id_nomenclature_tech_collect_campanule,
    v.id_nomenclature_grp_typ,
    v.comments AS visit_comments,
    v.meta_create_date AS visit_create_date,
    v.meta_update_date AS visit_update_date,
    v.observers_txt,
    visit_complements.bool_absence AS visit_bool_absence,
    visit_complements.accessibility AS visit_accessibility,
    visit_complements.etat_fauchage AS visit_etat_fauchage,
    visit_complements.etat_paturage AS visit_etat_paturage,
    visit_complements.etat_entretien_precedent AS visit_etat_entretien_precedent,
    -- visit_complements.vent AS visit_vent,
    -- visit_complements.num_passage AS visit_num_passage,
    -- visit_complements.temperature AS visit_temperature,
    -- visit_complements.couverture_nuageuse AS visit_couverture_nuageuse,
    -- visit_complements.etat_prairie_ligneux AS visit_etat_prairie_ligneux,
    -- visit_complements.etat_lande_domination AS visit_etat_lande_domination,
    -- visit_complements.etat_lande_domination_hauteur AS visit_etat_lande_domination_hauteur,
    visit_observers.observer_ids,
    visit_observers.observer_names,
    visit_observers.organismes_rattaches,
    o.id_observation,
    o.uuid_observation,
    o.cd_nom,
    t.lb_nom,
    t.nom_vern,
    o.comments AS observation_comments,
    o.id_digitiser AS observation_id_digitiser,
    observation_complements.observation_count,
    -- observation_complements.observation_id_nomenclature_sex,
    -- observation_complements.observation_id_nomenclature_stade,
    -- observation_complements.observation_id_nomenclature_eta_bio,
    -- observation_complements.observation_id_nomenclature_obj_denbr,
    -- observation_complements.observation_id_nomenclature_typ_denbr,
    ind.id_individual,
    ind.uuid_individual,
    ind.individual_name,
    ind.cd_nom AS individual_cd_nom,
    ind.id_nomenclature_sex AS individual_id_nomenclature_sex,
    ind.active AS individual_active,
    ind.comment AS individual_comment,
    ind.id_digitiser AS individual_id_digitiser,
    ind.meta_create_date AS individual_create_date,
    ind.meta_update_date AS individual_update_date
FROM gn_monitoring.t_observations o
JOIN gn_monitoring.t_base_visits v
  ON v.id_base_visit = o.id_base_visit
JOIN gn_commons.t_modules m
  ON m.id_module = v.id_module
LEFT JOIN gn_monitoring.t_module_complements mc
  ON mc.id_module = v.id_module
LEFT JOIN LATERAL (
    SELECT
        array_agg(DISTINCT cmt.id_type_site) AS module_type_site_ids,
        array_agg(DISTINCT bts.id_nomenclature_type_site) AS module_type_nomenclature_ids
        -- , array_agg(bts.config) AS module_type_configs
    FROM gn_monitoring.cor_module_type cmt
    LEFT JOIN gn_monitoring.bib_type_site bts
      ON bts.id_nomenclature_type_site = cmt.id_type_site
    WHERE cmt.id_module = v.id_module
) module_type_data ON TRUE
LEFT JOIN gn_monitoring.t_base_sites bs
  ON bs.id_base_site = v.id_base_site
LEFT JOIN gn_monitoring.t_site_complements sc
  ON sc.id_base_site = bs.id_base_site
LEFT JOIN gn_monitoring.t_sites_groups sg
  ON sg.id_sites_group = sc.id_sites_group
LEFT JOIN LATERAL (
    SELECT
        array_agg(commune_id) AS sites_group_commune,
        NULLIF(NULLIF(sg.data::jsonb ->> 'id_inventor', ''), 'null')::integer AS sites_group_id_inventor
    FROM (
        SELECT NULLIF(NULLIF(value, ''), 'null')::integer AS commune_id
        FROM jsonb_array_elements_text(COALESCE(sg.data::jsonb -> 'commune', '[]'::jsonb)) AS t(value)
    ) communes
) sites_group_info ON TRUE
LEFT JOIN LATERAL ref_geo.fct_get_altitude_intersection(bs.geom_local) alt(altitude_min, altitude_max)
  ON TRUE
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(sc.data::jsonb ->> 'radio_habitat', ''), 'null') AS site_radio_habitat,
        array_agg(protection_id) AS site_id_nomenclature_type_protection
    FROM (
        SELECT NULLIF(NULLIF(value, ''), 'null')::integer AS protection_id
        FROM jsonb_array_elements_text(COALESCE(sc.data::jsonb -> 'id_nomenclature_type_protection', '[]'::jsonb)) AS t(value)
    ) protections
) site_complements ON TRUE
LEFT JOIN LATERAL (
    SELECT
        array_agg(DISTINCT cst.id_type_site) AS site_type_site_ids,
        array_agg(DISTINCT bts.id_nomenclature_type_site) AS site_type_nomenclature_ids
        -- , array_agg(bts.config) AS site_type_configs
    FROM gn_monitoring.cor_site_type cst
    LEFT JOIN gn_monitoring.bib_type_site bts
      ON bts.id_nomenclature_type_site = cst.id_type_site
    WHERE cst.id_base_site = v.id_base_site
) site_type_data ON TRUE
LEFT JOIN LATERAL (
    SELECT array_agg(csa.id_area) AS site_area_ids
    FROM gn_monitoring.cor_site_area csa
    WHERE csa.id_base_site = v.id_base_site
) site_area_data ON TRUE
LEFT JOIN gn_meta.t_datasets d
  ON d.id_dataset = v.id_dataset
LEFT JOIN gn_monitoring.t_visit_complements vc
  ON vc.id_base_visit = v.id_base_visit
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(vc.data::jsonb ->> 'bool_absence', ''), 'null') AS bool_absence,
        NULLIF(NULLIF(vc.data::jsonb ->> 'accessibility', ''), 'null') AS accessibility,
        NULLIF(NULLIF(vc.data::jsonb ->> 'etat_fauchage', ''), 'null') AS etat_fauchage,
        NULLIF(NULLIF(vc.data::jsonb ->> 'etat_paturage', ''), 'null') AS etat_paturage,
        NULLIF(NULLIF(vc.data::jsonb ->> 'etat_entretien_precedent', ''), 'null') AS etat_entretien_precedent,
        NULLIF(NULLIF(vc.data::jsonb ->> 'vent', ''), 'null') AS vent,
        NULLIF(NULLIF(vc.data::jsonb ->> 'num_passage', ''), 'null') AS num_passage,
        NULLIF(NULLIF(vc.data::jsonb ->> 'temperature', ''), 'null') AS temperature,
        NULLIF(NULLIF(vc.data::jsonb ->> 'couverture_nuageuse', ''), 'null') AS couverture_nuageuse,
        NULLIF(NULLIF(vc.data::jsonb ->> 'etat_prairie_ligneux', ''), 'null') AS etat_prairie_ligneux,
        NULLIF(NULLIF(vc.data::jsonb ->> 'etat_lande_domination', ''), 'null') AS etat_lande_domination,
        NULLIF(NULLIF(vc.data::jsonb ->> 'etat_lande_domination_hauteur', ''), 'null') AS etat_lande_domination_hauteur
) visit_complements ON TRUE
LEFT JOIN LATERAL (
    SELECT
        array_agg(cvo.id_role) AS observer_ids,
        string_agg(DISTINCT concat_ws(' ', r.nom_role, r.prenom_role), ' ; ') AS observer_names,
        string_agg(DISTINCT org.nom_organisme, ' ; ') AS organismes_rattaches
    FROM gn_monitoring.cor_visit_observer cvo
    LEFT JOIN utilisateurs.t_roles r
      ON r.id_role = cvo.id_role
    LEFT JOIN utilisateurs.bib_organismes org
      ON org.id_organisme = r.id_organisme
    WHERE cvo.id_base_visit = v.id_base_visit
) visit_observers ON TRUE
LEFT JOIN gn_monitoring.t_observation_complements oc
  ON oc.id_observation = o.id_observation
LEFT JOIN LATERAL (
    SELECT
        NULLIF(NULLIF(oc.data::jsonb ->> 'count', ''), 'null')::integer AS observation_count,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_sex', ''), 'null')::integer AS observation_id_nomenclature_sex,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_stade', ''), 'null')::integer AS observation_id_nomenclature_stade,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_eta_bio', ''), 'null')::integer AS observation_id_nomenclature_eta_bio,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_obj_denbr', ''), 'null')::integer AS observation_id_nomenclature_obj_denbr,
        NULLIF(NULLIF(oc.data::jsonb ->> 'id_nomenclature_typ_denbr', ''), 'null')::integer AS observation_id_nomenclature_typ_denbr
) observation_complements ON TRUE
LEFT JOIN taxonomie.taxref t
  ON t.cd_nom = o.cd_nom
LEFT JOIN gn_monitoring.t_individuals ind
  ON ind.id_individual = o.id_individual
WHERE m.module_code = 'ipamob';
