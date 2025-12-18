# TP 04 : Réutiliser du code existant et gérer des environnements

## Introduction

Ce TP a pour but d'introduire les concepts suivants :
- les includes
- les extends
- les environnements
- les triggers

## Déroulé

### Utilisation de librairies pour les pipelines

Lorsque l'on travaille sur plusieurs projets au sein d'une même organisation, il est fréquent de retrouver des configurations de pipeline similaires : mêmes étapes de build, mêmes tests de qualité de code, mêmes déploiements. Plutôt que de dupliquer cette configuration dans chaque projet, GitLab CI permet de centraliser et de réutiliser du code à travers le mot-clé `include`.

#### Les différents types d'includes

GitLab CI propose plusieurs façons d'inclure des fichiers de configuration externes :

##### Include local

Permet d'inclure un fichier présent dans le même repository :
```yaml
include:
  - local: '/templates/build.yml'
```

##### Include project

Permet d'inclure un fichier présent dans un autre projet GitLab :
```yaml
include:
  - project: 'groupe/projet-templates'
    ref: 'main'
    file: '/templates/build.yml'
```

> Le `ref` peut être une branche, un tag ou un commit SHA.

##### Include remote

Permet d'inclure un fichier accessible via une URL publique :
```yaml
include:
  - remote: 'https://example.com/templates/build.yml'
```

##### Include template

Permet d'inclure un template fourni par GitLab :
```yaml
include:
  - template: 'Auto-DevOps.gitlab-ci.yml'
```

> La liste des templates disponibles est consultable dans la [documentation officielle](https://docs.gitlab.com/ci/examples/#cicd-templates).

#### Mise en pratique

Pour ce TP, nous allons créer un projet dédié aux templates de pipeline, puis l'utiliser dans notre projet principal.

Créez un nouveau projet nommé `ci-templates` (via l'interface GitLab ou le bouton `New project`), et ajoutez-y un fichier `templates/hello.yml` avec le contenu suivant :
```yaml
.hello-template:
  script:
    - echo "Hello depuis le template !"
```

> Le point (`.`) devant le nom du job indique qu'il s'agit d'un job "caché" : il ne sera pas exécuté directement, mais pourra être utilisé comme base pour d'autres jobs.

Ensuite, dans votre projet principal, modifiez le fichier `.gitlab-ci.yml` pour inclure ce template :
```yaml
include:
  - project: 'root/ci-templates'
    ref: 'main'
    file: '/templates/hello.yml'

stages:
  - build

mon-job:
  stage: build
  extends: .hello-template
```

Lancez le pipeline et vérifiez que le job `mon-job` exécute bien le script défini dans le template.

> Consultez la [documentation officielle](https://docs.gitlab.com/ci/yaml/includes.html) pour plus d'informations sur les includes.

### Personnalisation de librairies

Les templates sont utiles, mais leur véritable puissance réside dans leur capacité à être personnalisés. Le mot-clé `extends` permet d'hériter d'un job template et de surcharger ou compléter ses propriétés.

#### Héritage simple

Lorsqu'un job utilise `extends`, il hérite de toutes les propriétés du job parent :
```yaml
.template-base:
  image: alpine:latest
  before_script:
    - echo "Préparation..."
  script:
    - echo "Script par défaut"

mon-job:
  extends: .template-base
  # Ce job hérite de l'image, du before_script et du script
```

#### Surcharge de propriétés

Vous pouvez surcharger les propriétés héritées en les redéfinissant :
```yaml
.template-base:
  image: alpine:latest
  script:
    - echo "Script par défaut"
  variables:
    MESSAGE: "Hello"

mon-job:
  extends: .template-base
  script:
    - echo "Script personnalisé"
  variables:
    MESSAGE: "Bonjour"
    AUTRE_VARIABLE: "Valeur"
```

Dans cet exemple, `mon-job` :
- conserve l'`image` du template (`alpine:latest`)
- remplace le `script` par sa propre version
- fusionne les `variables` : `MESSAGE` est surchargé et `AUTRE_VARIABLE` est ajouté

> Les propriétés de type dictionnaire (comme `variables`) sont fusionnées, tandis que les propriétés de type liste (comme `script`) sont remplacées.

#### Héritage multiple

Un job peut hériter de plusieurs templates :
```yaml
.template-image:
  image: python:3.11

.template-script:
  script:
    - python --version

mon-job:
  extends:
    - .template-image
    - .template-script
```

> En cas de conflit entre les templates, c'est le dernier listé qui prend la précédence.

#### Mise en pratique

Modifiez le fichier `templates/hello.yml` dans votre projet `ci-templates` pour proposer un template plus complet :
```yaml
.build-template:
  image: alpine:latest
  variables:
    BUILD_MESSAGE: "Construction en cours..."
  before_script:
    - echo "Initialisation du build"
  script:
    - echo "${BUILD_MESSAGE}"
    - echo "Build terminé !"
```

Puis, dans votre projet principal, utilisez ce template en personnalisant le message :
```yaml
include:
  - project: 'root/ci-templates'
    ref: 'main'
    file: '/templates/hello.yml'

stages:
  - build

mon-build:
  stage: build
  extends: .build-template
  variables:
    BUILD_MESSAGE: "Construction de mon application..."
```

> Consultez la [documentation officielle](https://docs.gitlab.com/ci/yaml/#extends) pour plus d'informations sur le mot-clé `extends`.

### Gestion des différents environnements de déploiement

Dans le TP 01, nous avons brièvement évoqué les environnements. Les environnements GitLab CI permettent de suivre les déploiements de votre application sur différentes cibles (développement, staging, production, etc.).

#### Déclaration d'un environnement

Un environnement est déclaré dans un job avec le mot-clé `environment` :
```yaml
deploy-staging:
  stage: deploy
  script:
    - echo "Déploiement sur staging..."
  environment:
    name: staging
    url: https://staging.example.com
```

Après l'exécution de ce job, vous pourrez retrouver l'environnement dans [`Operate` > `Environments`](http://gitlab/root/sample-project/-/environments), avec un lien direct vers l'URL spécifiée.

#### Environnements dynamiques

Les environnements peuvent être dynamiques, notamment pour créer des environnements de review par branche :
```yaml
deploy-review:
  stage: deploy
  script:
    - echo "Déploiement de la review..."
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    on_stop: stop-review
  rules:
    - if: $CI_MERGE_REQUEST_IID

stop-review:
  stage: deploy
  script:
    - echo "Suppression de l'environnement de review..."
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  rules:
    - if: $CI_MERGE_REQUEST_IID
      when: manual
```

> La variable `$CI_COMMIT_REF_SLUG` contient le nom de la branche, formaté pour être utilisé dans une URL (caractères spéciaux remplacés).

#### Actions sur les environnements

Le mot-clé `action` permet de définir le type d'action effectuée sur l'environnement :
- `start` (par défaut) : démarre ou met à jour l'environnement
- `prepare` : prépare l'environnement sans le démarrer
- `stop` : arrête l'environnement
- `verify` : vérifie l'état de l'environnement
- `access` : accède à l'environnement sans le modifier

#### Protection des environnements

Les environnements peuvent être protégés pour restreindre qui peut y déployer. Dans [`Operate` > `Environments`](http://gitlab/root/sample-project/-/environments), cliquez sur l'environnement souhaité, puis sur `Edit`. Vous pourrez alors définir :
- les utilisateurs ou groupes autorisés à déployer
- les branches autorisées à déclencher un déploiement
- une approbation requise avant le déploiement

#### Mise en pratique

Créez un pipeline avec trois jobs de déploiement pour trois environnements différents :
```yaml
stages:
  - build
  - deploy

build:
  stage: build
  script:
    - echo "Construction de l'application"

deploy-dev:
  stage: deploy
  script:
    - echo "Déploiement en développement"
  environment:
    name: development

deploy-staging:
  stage: deploy
  script:
    - echo "Déploiement en staging"
  environment:
    name: staging
  when: manual

deploy-prod:
  stage: deploy
  script:
    - echo "Déploiement en production"
  environment:
    name: production
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

Lancez le pipeline, puis rendez-vous dans [`Operate` > `Environments`](http://gitlab/root/sample-project/-/environments) pour visualiser vos environnements.

> Consultez la [documentation officielle](https://docs.gitlab.com/ci/environments/) pour plus d'informations sur les environnements.

### Lancement de pipelines sur d'autres projets

Dans certains cas, vous pourriez avoir besoin de déclencher un pipeline sur un autre projet. Par exemple, après avoir construit une librairie, vous pourriez vouloir déclencher les tests d'intégration d'un projet qui l'utilise. Le mot-clé `trigger` permet de répondre à ce besoin.

#### Déclenchement d'un pipeline sur un autre projet

Pour déclencher un pipeline sur un autre projet, utilisez `trigger` avec le chemin du projet :
```yaml
stages:
  - build
  - trigger

build:
  stage: build
  script:
    - echo "Construction terminée"

trigger-autre-projet:
  stage: trigger
  trigger:
    project: groupe/autre-projet
    branch: main
```

> Le projet cible doit autoriser les déclenchements depuis d'autres projets. Cela se configure dans [`Settings` > `CI/CD` > `Pipeline trigger tokens`](http://gitlab/root/sample-project/-/settings/ci_cd#js-pipeline-triggers).

#### Passage de variables

Vous pouvez passer des variables au pipeline déclenché :
```yaml
trigger-avec-variables:
  stage: trigger
  trigger:
    project: groupe/autre-projet
    branch: main
  variables:
    VERSION: "1.2.3"
    ENVIRONNEMENT: "staging"
```

#### Stratégies de déclenchement

Le mot-clé `strategy` permet de définir le comportement du job déclencheur :
```yaml
trigger-et-attendre:
  stage: trigger
  trigger:
    project: groupe/autre-projet
    branch: main
    strategy: depend
```

Avec `strategy: depend`, le job déclencheur attendra la fin du pipeline déclenché et héritera de son statut (succès ou échec).

#### Pipelines enfants (Child Pipelines)

Une variante des triggers est les pipelines enfants. Au lieu de déclencher un pipeline sur un autre projet, vous déclenchez un pipeline défini dans un autre fichier du même projet :
```yaml
stages:
  - build
  - tests

build:
  stage: build
  script:
    - echo "Construction terminée"

tests:
  stage: tests
  trigger:
    include: tests/.gitlab-ci.yml
    strategy: depend
```

Cette approche est utile pour :
- découper un pipeline complexe en plusieurs fichiers
- exécuter des configurations de pipeline générées dynamiquement
- paralléliser des ensembles de tests

> Le fichier de pipeline enfant peut être généré dynamiquement par un job précédent, puis passé en artifact.

#### Mise en pratique

Créez un second projet nommé `projet-downstream` avec le fichier `.gitlab-ci.yml` suivant :
```yaml
stages:
  - test

test:
  stage: test
  script:
    - echo "Tests déclenchés depuis le projet upstream"
    - echo "Version reçue: ${VERSION:-non définie}"
```

Puis, dans votre projet principal, ajoutez un job de trigger :
```yaml
stages:
  - build
  - trigger

build:
  stage: build
  script:
    - echo "Build terminé"

trigger-downstream:
  stage: trigger
  trigger:
    project: root/projet-downstream
    branch: main
    strategy: depend
  variables:
    VERSION: "1.0.0"
```

Lancez le pipeline et observez le déclenchement du pipeline sur le projet downstream.

> Consultez la [documentation officielle](https://docs.gitlab.com/ci/pipelines/downstream_pipelines.html) pour plus d'informations sur les triggers et les pipelines enfants.

## Conclusion

Félicitations, vous avez maintenant appris à réutiliser du code avec les includes et extends, à gérer différents environnements de déploiement, et à déclencher des pipelines sur d'autres projets avec les triggers. Ces fonctionnalités vous permettent de construire des pipelines modulaires, maintenables et adaptés aux workflows complexes.
