# IPAMOB

Sous-module de saisie GeoNature Monitoring du protocole IPAMOB (Indicateur des Papillons des Milieux Ouverts de Bretagne) - Bretagne Vivante dans le cadre de l'ORIC (Observatoire régional des Invertébrés Continentaux)

## Documentation

## protocole
basé sur STERF

Création de la liste des espèces => ok mais validation par les experts

4 passages dans l'année (mai a aout) => 1 par mois avec 2 semaines d'intervalle minimum
10 min environ => avec pause possible pour identifier
Transect de 200m environ (10min en marchant lentement tout droit)
cube virtuel de 5m devant l'observateur
Conseil : passage entre 11 et 17h




## Architecture

Group_site = aire
site = transect (pas de limite de nb de transect)
visit = passage
observation = individu

### Groupe Site
Nom Aire (réserve de machin)
Commune (calculé)
Commentaire 

### Site
Num du transect
Habitat (Pelouse, Lande , Prairie) -> pas besoin plus précis ( voir pour intégrer la nomenclature STERF après)
Type de site (Exploitation agricole, RNR, RNN, Natura 2000, propriété communale)
Géométrie ( LineString)
Commentaire 

### Visite
Date
Numéro de la visite (1,2,3...)
Condition météo (vent, pluie, Temp) => si pluie = annulation du passage 
Condition de l'Habitat (Pelouse, Lande , Prairie) 
==> (fraichement fauchée, fraichement paturée, entretenue l'année précédente)
==> liste dépendante du choix dans site

Commentaire passage

### observation

Stade de vie = adulte
=> Identification uniquement des adultes

Objet denombrement = individu
sexe = indeterminé
=> Difficulté d'identification et non nécessaire pour l'objectif

Type denombrement -> Nombre Compté => pas de nombre max
Taxon par défaut = rhopalocera
Commentaire observation



7 indices calculés a la volée

## Résultats

### Production de la vue de synthese
### Production de la vue d'analyse
Année , nb de passage réalisé

### Graph en toile d'araigné (produit sous R a partir de la vue d'analyse)
Système de données avec indicateur relatif, calculé sur les données de l'année
Tout en aillant le meilleur et le moins de toutes les années


## Bénévoles
Au moins 20 personnes par la première année

### Test terrain

### Tuto / Formation

### Récupération / Intégration des vieilles données


============



=========
## Questions a poser :

=========

## Installation 

### Prérequis

- une instance GeoNature, dotée du module monitorings. 
- Une liste de taxons (cd_nom) en rapport avec le protocole.
- Une liste d'observateurs (nom utilisateur).
- Un groupe pour affecter la liste des observateurs et donner les droits associés au groupe.

Il faut créer un JDD avec le module en paramètre

geonature monitorings install --help

cd
source ~/geonature/backend/venv/bin/activate

https://github.com/PnX-SI/gn_module_monitoring/pull/224

geonature monitorings install <mon_chemin_absolu_vers_mon_module> <mon_module_code>
geonature monitorings install /home/geonatureadmin/protocoles_suivi/nicheurs_oiseaux_marins nicheurs_oiseaux_marins

geonature monitorings install /home/geonatureadmin/geonature/backend/media/monitorings/nicheurs_oiseaux_marins

geonature monitorings install nicheurs_oiseaux_marins

manque le ls, a retrouver

sudo systemctl restart geonature
deactivate


Si vous utilisez un autre "module_code" que ipamob tout en minuscule, vous devrez adapter les scripts SQL d'exports pour récupérer les données du modules dans vos exports standards et d'analyse.

