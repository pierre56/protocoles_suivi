

https://geonature.bretagne-vivante.org/api/admin/bibtypesite/edit/?id=1326&url=/api/admin/bibtypesite/?page%3D1

INSERT INTO gn_monitoring.bib_type_site
(id_nomenclature_type_site)
from 
SELECT id_nomenclature
from 
ref_nomenclatures.t_nomenclatures
where id_type = 116
on error do nothing

INSERT INTO gn_monitoring.cor_site_type
(id_type_site, id_base_site)
select distinct 1326, b.id_base_site 
from gn_monitoring.t_site_complements b
where id_sites_group in (
288
,289
,290
,386
,409
,438
,458)
;

select id_base_site 
from gn_monitoring.t_site_complements
where id_sites_group in (
288
,289
,290
,386
,409
,438
,458)