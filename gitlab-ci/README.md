# Introduction

L'ensemble de ces TPs a pour but d'initier un DevOps à Gitlab CI.

## Qu'est ce que GitLab CI ?

GitLab CI est un outil permettant d'automatiser une suite d'actions sous la forme d'un "pipeline". Ce pipeline peut être déclenché par plusieurs actions distinctes, la plupart étant en rapport avec Git (commit, merge request, etc.), et appliquer des conditions pour effectuer telle ou telle action en fonction du déclencheur (nature, titre, auteur, etc.), du contexte, ou même du résultat d'une action précédente. Les actions sont séparées en différents "jobs", eux-mêmes regroupés en "stages" pour permettre l'organisation des tâches.

GitLab CI est, comme son nom l'indique, intimement lié au COTS GitLab, et il n'est pas possible d'utiliser le premier sans une instance du second. L'inverse est cependant possible : il est possible d'utiliser GitLab sans solliciter GitLab CI, mais on perd alors une partie significative des possibilités offertes par le COTS.

Là où GitLab sert à orchestrer les pipelines, un "runner" GitLab CI sert à les exécuter. Il en existe plusieurs sortes, qui sont référencées dans [la documentation officielle](https://docs.gitlab.com/runner/executors/). Ici, nous allons nous concentrer sur le type "Docker" : chaque étape des pipelines tournera sur une image Docker adaptée et propre, permettant une meilleure reproductibilité.

Ainsi, les fichiers de déclaration des pipelines seront toujours au format YAML, quel que soit l'executor, mais avec Docker, nous allons devoir préciser en plus le nom de l'image sur laquelle le code sera exécuté.

# Prérequis

Cette série de TPs va introduire progressivement les concepts de GitLab CI, mais nous allons avoir besoin de plusieurs éléments pour cela.

## GitLab et GitLab CI

Comme précisé ci-dessus, GitLab CI est un composant du produit GitLab. Il faut donc une instance de ce dernier pour orchestrer les différents pipelines que nous allons être amenés à créer. Cette instance devra avoir accès sinon à Internet, au moins à un registre de conteneurs où vous pourrez déposer les images nécessaires (si elles ne sont pas déjà présentes).

Dans l'éventualité où vous n'avez pas une instance de GitLab et un runner Docker à disposition, ce projet embarque des fichiers `setup.sh` et `docker-compose.yml`, qui, exécutés sur un environnement Linux disposant de Docker, vont créer et pré-configurer ces prérequis sous la forme de conteneurs : un GitLab et deux runners. L'ensemble des TPs sont conçus pour ce cas d'usage, il est possible que vous n'ayez pas accès à certaines pages si vous utilisez une instance préexistante gérée par un tiers.

> La version de GitLab déployée par le script `setup.sh` a été figée à `17.11.0` afin de se prémunir contre des changements d'API et d'interface. Si vous utilisez une version plus récente et que vous constatez des écarts, n'hésitez pas à en avertir l'auteur.

Vous pouvez maintenant lancer le script `setup.sh`.

> Au premier lancement, il est normal que le conteneur `gitlab` reste assez longtemps au statut `Waiting` : celui-ci attend la fin de l'initialisation de GitLab avant de se déclarer `Healthy`.

Une fois le script terminé, celui-ci affichera les identifiants de connexion du compte `root`. Par principe, n'oubliez pas de changer le mot de passe à l'URL suivante : http://gitlab/-/user_settings/password/edit

# Les TPs

Chaque TP est conçu pour introduire un nombre limité de concepts afin de ne pas vous surcharger d'informations.

## TP 01 : Vérifier l'état des runners et lancer un premier pipeline

[Ce TP](TP_01) a pour but d'apprendre à :
- vérifier la présence de runners
- configurer un projet pour utiliser la CI/CD
- créer un pipeline basique

## TP 02 : Contrôler l'exécution des jobs

[Ce TP](TP_02) a pour but d'introduire les concepts suivants :
- les images
- les artifacts
- les services
- les variables
- les needs
- les when

## TP 03 : Utiliser les différentes entrées et sorties

[Ce TP](TP_03) a pour but d'introduire les concepts suivants :
- les inputs
- les secrets
- les before_script/after_script
- les schedules

## TP 04 : Réutiliser du code existant et gérer des environnements

[Ce TP](TP_04) a pour but d'introduire les concepts suivants :
- les includes
- les extends
- les environnements
- les triggers

## TP 05 : Synthèse

[Ce TP](TP_05) a pour but de réutiliser l'ensemble des connaissances acquises pour écrire un pipeline complexe de zéro.

# Pour aller plus loin

Pour aller plus loin, vous pouvez vous renseigner sur les sujets suivants :
- les [rules](https://docs.gitlab.com/ci/yaml/#rules), qui permettent de contrôler l'ajout ou non d'un job à un pipeline (contrairement à `when` qui va toujours ajouter les jobs, mais déterminer les conditions dans lesquelles ils vont s'exécuter)
- les [dependencies](https://docs.gitlab.com/ci/yaml/#dependencies), qui permettent à un job de lister explicitement les jobs de stages précédents dont il doit récupérer les artifacts, mais sans créer une relation de dépendance comme `needs`
- le [cache](https://docs.gitlab.com/ci/caching/), qui permet de stocker temporairement des fichiers pour accélérer les pipelines
- le [parallel](https://docs.gitlab.com/ci/yaml/#parallel), qui permet d'exécuter plusieurs fois un job au sein d'un même pipeline, par exemple pour une compilation pour plusieurs architectures, ou un déploiement sur plusieurs environnements

# Crédits

- TBD
