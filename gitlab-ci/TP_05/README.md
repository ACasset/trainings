# TP 05 : Synthèse

## Introduction

Ce TP a pour but de réutiliser l'ensemble des connaissances acquises pour écrire un pipeline complexe de zéro.

## Prérequis

Ce TP part du principe que vous venez de dérouler les TPs 01 à 04.

Vous devriez donc déjà avoir à disposition :
- une instance GitLab avec des runners Docker fonctionnels
- une bonne compréhension des concepts de base de GitLab CI (stages, jobs, images, services)
- une maîtrise des mécanismes avancés (variables, artifacts, includes, extends, environments, triggers)

## Déroulé

Ce TP est un TP de synthèse où rien n'est fourni.

L'objectif est d'écrire un pipeline complet pour une application web fictive, en utilisant tous les concepts vus précédemment. L'application est composée d'un frontend (HTML/CSS/JS) et d'un backend (API Python), et doit être déployée sur plusieurs environnements.

### Contexte

Vous êtes DevOps dans une entreprise qui développe une application web. L'équipe de développement vous demande de mettre en place une pipeline CI/CD complète qui :

1. **Valide le code** : lint et tests unitaires
2. **Construit l'application** : génération des artifacts de build
3. **Exécute des tests d'intégration** : avec une base de données de test
4. **Déploie sur plusieurs environnements** : développement, staging et production
5. **Notifie l'équipe** : en cas de succès ou d'échec

### Cahier des charges

Votre pipeline doit respecter les contraintes suivantes :

#### Structure du pipeline

- Définir les stages suivants : `lint`, `test`, `build`, `integration`, `deploy`, `notify`
- Utiliser des images Docker adaptées à chaque job
- Organiser le code de façon modulaire avec des templates réutilisables

#### Jobs de validation

- Un job de lint pour le frontend (utiliser une image Node.js et simuler un `npm run lint`)
- Un job de lint pour le backend (utiliser une image Python et simuler un `python -m pylint`)
- Un job de tests unitaires pour le backend (simuler un `pytest`)

#### Jobs de build

- Un job de build pour le frontend qui génère un artifact (simuler un `npm run build` et créer un fichier `frontend-build.txt`)
- Un job de build pour le backend qui génère un artifact (créer un fichier `backend-build.txt`)
- Les artifacts doivent être conservés pendant 1 semaine

#### Jobs de tests d'intégration

- Un job qui utilise un service PostgreSQL
- Ce job doit récupérer les artifacts des jobs de build
- Simuler des tests d'intégration entre le frontend et le backend

#### Jobs de déploiement

- Trois jobs de déploiement : `deploy-dev`, `deploy-staging`, `deploy-prod`
- Chaque job doit déclarer son environnement correspondant
- Le déploiement en production doit être manuel et réservé à la branche `main`
- Le déploiement en staging doit être manuel
- Le déploiement en développement doit être automatique

#### Jobs de notification

- Un job qui s'exécute en cas de succès du pipeline
- Un job qui s'exécute en cas d'échec du pipeline
- Les jobs doivent afficher un message approprié

#### Contraintes supplémentaires

- Utiliser des variables pour les valeurs réutilisées (version de l'application, URLs des environnements, etc.)
- Utiliser `before_script` pour afficher des informations de contexte (date, branche, commit)
- Utiliser des `needs` pour optimiser le flux d'exécution
- Permettre à un job de build d'échouer sans bloquer le pipeline (avec un code d'erreur spécifique)

### Suggestions

Avant de vous lancer dans l'écriture de votre pipeline, considérez les points suivants :

- Commencez par dessiner le flux de votre pipeline sur papier ou avec un outil de diagramme
- Testez chaque job individuellement avant de les assembler
- Utilisez la fonctionnalité `CI Lint` de GitLab (dans `Build` > `Pipeline editor` > `Validate`) pour vérifier la syntaxe de votre fichier
- N'hésitez pas à consulter la [documentation officielle](https://docs.gitlab.com/ci/yaml/) en cas de doute

### Structure suggérée

Voici une structure de départ pour vous aider :

```yaml
# Variables globales
variables:
  APP_VERSION: "1.0.0"
  # Ajoutez vos variables ici

# Configuration par défaut
default:
  before_script:
    # Ajoutez votre before_script ici

# Définition des stages
stages:
  - lint
  - test
  - build
  - integration
  - deploy
  - notify

# Templates (à compléter)
.deploy-template:
  # Définissez un template commun pour les déploiements

# Jobs de lint
lint-frontend:
  stage: lint
  # À compléter

lint-backend:
  stage: lint
  # À compléter

# Jobs de test
test-backend:
  stage: test
  # À compléter

# Jobs de build
build-frontend:
  stage: build
  # À compléter

build-backend:
  stage: build
  # À compléter

# Job d'intégration
integration-tests:
  stage: integration
  # À compléter

# Jobs de déploiement
deploy-dev:
  stage: deploy
  # À compléter

deploy-staging:
  stage: deploy
  # À compléter

deploy-prod:
  stage: deploy
  # À compléter

# Jobs de notification
notify-success:
  stage: notify
  # À compléter

notify-failure:
  stage: notify
  # À compléter
```

### Critères de validation

Votre pipeline sera considéré comme réussi si :

1. Le fichier `.gitlab-ci.yml` est syntaxiquement correct
2. Le pipeline s'exécute sans erreur (à l'exception des échecs volontaires)
3. Les artifacts sont correctement générés et transmis entre les jobs
4. Les environnements sont correctement créés dans GitLab
5. Le flux d'exécution respecte les dépendances définies
6. Les jobs de notification s'exécutent au bon moment

### Pour aller plus loin

Si vous terminez rapidement, vous pouvez enrichir votre pipeline avec :

- Des pipelines enfants pour séparer les tests frontend et backend
- Une génération dynamique de la configuration (avec un job qui génère un fichier YAML utilisé ensuite)
- Une intégration avec un projet externe (simuler un déclenchement de tests E2E)
- L'utilisation de `rules` pour conditionner finement l'exécution des jobs
- La mise en place d'un cache pour accélérer les jobs répétitifs

## Conclusion

Félicitations, vous avez maintenant acquis les compétences nécessaires pour concevoir et implémenter des pipelines GitLab CI complets et professionnels. Les concepts abordés dans cette formation vous permettront de mettre en place des workflows CI/CD adaptés à la plupart des projets, qu'il s'agisse d'applications web, de librairies, d'infrastructures ou de tout autre type de projet logiciel.

N'oubliez pas que la documentation officielle de GitLab CI est une ressource précieuse : elle est régulièrement mise à jour et contient de nombreux exemples pour des cas d'usage variés.
