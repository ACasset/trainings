# TP 03 : Utiliser les différentes entrées et sorties

## Introduction

Ce TP a pour but d'introduire les concepts suivants :
- les inputs
- les secrets
- les before_script/after_script
- les schedules

## Déroulé

### Prise en compte d'entrées utilisateur

Nous avons vu que certains pipelines sont conçus pour se lancer automatiquement lors d'un commit par exemple, mais il est facile d'imaginer avoir besoin de procéder à des lancements manuels : typiquement pour générer un livrable à partir d'un tag, ou pour procéder à un déploiement si on ne souhaite pas que ce dernier soit automatique.

Dans ce genre de cas, on peut avoir le besoin de préciser certaines valeurs qui seront utilisées dans le pipeline : les `inputs` sont là pour ça, mais ils demandent de restructurer légèrement le fichier YAML du pipeline.

Vous pouvez repartir du fichier de pipeline du TP précédent si vous le souhaitez, mais il sera plus simple de créer un nouveau projet et de repartir d'une base saine (ce qui sera le cas dans le corrigé de ce TP).

Quelle que soit votre décision, rajoutez le bloc suivant au début de votre fichier :
```yaml
spec:
  inputs:
    premier-input:
      description: Ceci est le premier input
    second-input:
      description: Ceci est le second input
---
```

Vous allez maintenant pouvoir 1° renseigner ces inputs lorsque vous lancez manuellement le pipeline, et 2° vous servir de ces inputs avec la syntaxe `$[[ inputs.premier-input ]]`.

Faites un simple echo dans un job existant pour constater que l'input est bien transmis.

Lorsque vous allez commit, le pipeline va tenter de se déclencher, et vous renvoyer une erreur ressemblant à "`premier-input` input: required value has not been provided`" : les inputs n'ayant pas de valeur par défaut, les déclenchement automatiques de pipelines sont désormais impossibles.

Vous pouvez pallier à cela en déclarant simplement la clé `default` pour chaque input :
```yaml
spec:
  inputs:
    premier-input:
      description: Ceci est le premier input
      default: "Valeur par défaut pour le premier input"
    second-input:
      description: Ceci est le second input
      default: "Valeur par défaut pour le second input"
```



La puissance des inputs est qu'ils sont utilisables n'importe où : vous pouvez parfaitement les utiliser pour définir par exemple le stage d'un job comme suit :
```yaml
job_avec_un_stage_variable:
  stage: $[[ inputs.job-stage ]]
  script:
    - echo "Execution dans le stage $[[ inputs.job-stage ]]"
```

Mais, si vous vous souvenez du fonctionnement des stages, ces derniers doivent être déclarés dans la clé `stages` à la racine du pipeline. En laissant l'utilisateur taper la valeur de son choix, on peut facilement imaginer un cas de figure où le stage renseigné n'est pas valide. On peut alors spécifier des `options` à l'`input` pour éviter cela :
```yaml
spec:
  inputs:
    job-stage:
      options: ['build', 'test', 'deploy']
```

Comme toute entrée utilisateur, soyez extrêmement vigilants lorsque vous l'utilisez : il est essentiel de mesurer le risque pour éviter des déconvenues. Concrètement, cela pourrait se manifester ainsi :
```yaml
hello_world:
  stage: build
  script:
    - git tag $[[ inputs.version ]]
    - git push origin $[[ inputs.version ]]
```

Si jamais l'utilisateur renseignait quelque chose comme `idontcare && rm -rf --no-preserve-root /` dans l'input, cela pourrait avoir des conséquences fâcheuses (sous réserve que l'on ne soit pas dans un conteneur et que le compte utilisé par GitLab CI ait les droits suffisants... mais vous avez l'idée).

On peut alors maîtriser ce risque en utilisant `type` et/ou `regex` dans la définitions des inputs :
```yaml
spec:
  inputs:
    version:
      type: string
      regex: ^\w+$
      options: ['build', 'test', 'deploy']
```

> Les valeurs possibles de `type` sont : `string` (valeur par défaut), `array`, `number` et `boolean`.

> Comme d'habitude, pour en savoir plus, consultez la [documentation officielle](https://docs.gitlab.com/ci/inputs/)

### Utilisation de données sensibles

Nous avons vu dans le TP précédent l'utilisation de variables pour stocker des valeurs. Cependant, certaines de ces valeurs sont sensibles (mots de passe, tokens d'API, clés SSH, etc.) et ne doivent pas être stockées en clair dans le fichier `.gitlab-ci.yml`, qui est versionné et potentiellement accessible à tous.

GitLab propose deux mécanismes pour gérer ces secrets : les variables CI/CD et les secrets provenant de gestionnaires externes.

#### Variables CI/CD

Les variables CI/CD sont des variables définies dans l'interface de GitLab, et qui seront injectées dans les pipelines lors de leur exécution. Elles peuvent être définies à plusieurs niveaux : instance, groupe ou projet.

Pour définir une variable au niveau du projet, rendez-vous dans [`Settings` > `CI/CD` > `Variables`](http://gitlab/root/sample-project/-/settings/ci_cd#js-cicd-variables-settings), puis cliquez sur `Add variable`.

Vous allez pouvoir renseigner plusieurs champs :
- `Key` : le nom de la variable, qui sera utilisé pour la référencer dans le pipeline (par exemple `MON_SECRET`)
- `Value` : la valeur de la variable
- `Type` : le type de la variable, qui peut être `Variable` (valeur simple) ou `File` (le contenu sera écrit dans un fichier temporaire, et la variable contiendra le chemin vers ce fichier)
- `Environment scope` : permet de restreindre la variable à un ou plusieurs environnements (nous verrons les environnements dans le TP suivant)
- `Protect variable` : si coché, la variable ne sera accessible que dans les pipelines exécutés sur des branches ou des tags protégés
- `Mask variable` : si coché, la valeur de la variable sera masquée dans les logs des jobs (remplacée par `[MASKED]`)
- `Expand variable reference` : si coché, GitLab va interpréter les références à d'autres variables dans la valeur (par exemple `${AUTRE_VARIABLE}`)

Créez une variable `MON_SECRET` avec une valeur de votre choix, en cochant `Mask variable` pour éviter qu'elle n'apparaisse dans les logs.

Vous pouvez maintenant utiliser cette variable dans votre pipeline comme n'importe quelle autre variable :
```yaml
afficher-secret:
  stage: build
  script:
    - echo "La valeur du secret est ${MON_SECRET}"
```

> Attention, le masquage n'est pas infaillible : si vous affichez la variable d'une façon détournée (par exemple en la retournant caractère par caractère), elle pourra apparaître dans les logs. Le masquage est une protection contre les erreurs involontaires, pas contre les actions malveillantes.

> Il est aussi possible de définir des variables CI/CD au niveau d'un groupe, ce qui permet de les partager entre plusieurs projets. Pour cela, rendez-vous dans les paramètres CI/CD du groupe.

#### Secrets provenant de gestionnaires externes

Pour les environnements plus exigeants en matière de sécurité, GitLab propose également une intégration avec des gestionnaires de secrets externes tels que HashiCorp Vault, Azure Key Vault ou Google Cloud Secret Manager. Cette intégration utilise le mot-clé `secrets` dans le fichier `.gitlab-ci.yml`.

Voici un exemple d'utilisation avec HashiCorp Vault :
```yaml
job_avec_secret:
  stage: build
  secrets:
    MON_SECRET_VAULT:
      vault: production/db/password@secrets
  script:
    - echo "Le secret récupéré depuis Vault est disponible dans ${MON_SECRET_VAULT}"
```

> L'intégration avec des gestionnaires de secrets externes nécessite une configuration préalable au niveau de l'instance ou du groupe GitLab. Consultez la [documentation officielle](https://docs.gitlab.com/ci/secrets/) pour plus d'informations.

### Exécution d'actions antérieures et postérieures aux scripts

Il est fréquent d'avoir besoin d'exécuter des commandes avant ou après le script principal d'un job : par exemple, installer des dépendances, configurer l'environnement, ou nettoyer des fichiers temporaires. Les mots-clés `before_script` et `after_script` répondent à ce besoin.

#### before_script

Le `before_script` est exécuté avant le `script` principal du job. Il est utile pour préparer l'environnement d'exécution :
```yaml
job-avec-preparation:
  stage: build
  before_script:
    - echo "Préparation de l'environnement..."
    - apk add --no-cache curl
  script:
    - curl --version
    - echo "Le script principal s'exécute"
```

#### after_script

Le `after_script` est exécuté après le `script` principal, que celui-ci ait réussi ou échoué. Il est utile pour les actions de nettoyage :
```yaml
job-avec-nettoyage:
  stage: build
  script:
    - echo "Le script principal s'exécute"
    - echo "fichier temporaire" > /tmp/mon_fichier.txt
  after_script:
    - echo "Nettoyage..."
    - rm -f /tmp/mon_fichier.txt
```

> Important : le `after_script` s'exécute dans un contexte différent du `script` principal. Cela signifie que les variables d'environnement définies dans le `script` ne seront pas disponibles dans le `after_script`. De plus, le `after_script` a un timeout par défaut de 5 minutes, indépendant du timeout du job.

#### Utilisation globale

Comme pour les `services`, vous pouvez définir des `before_script` et `after_script` globaux dans la clé `default` :
```yaml
default:
  before_script:
    - echo "Ceci s'exécute avant chaque job"
  after_script:
    - echo "Ceci s'exécute après chaque job"

job-1:
  stage: build
  script:
    - echo "Job 1"

job-2:
  stage: test
  script:
    - echo "Job 2"
  # On peut surcharger le before_script global
  before_script:
    - echo "Préparation spécifique au job 2"
```

Ajoutez un `before_script` global qui affiche la date et l'heure de début d'exécution, et un `after_script` global qui affiche la date et l'heure de fin. Vous constaterez ainsi facilement la durée d'exécution de chaque job.

> Consultez la [documentation officielle](https://docs.gitlab.com/ci/yaml/#before_script) pour plus d'informations sur ces mots-clés.

### Planification de pipelines

Jusqu'à présent, nous avons déclenché des pipelines manuellement ou automatiquement lors d'un commit. Mais il existe d'autres façons de déclencher un pipeline, notamment la planification.

La planification permet de déclencher des pipelines à intervalles réguliers, comme une tâche cron. C'est utile pour des opérations récurrentes comme des sauvegardes, des audits de sécurité, ou des tests de non-régression nocturnes.

#### Création d'une planification

Pour créer une planification, rendez-vous dans [`Build` > `Pipeline schedules`](http://gitlab/root/sample-project/-/pipeline_schedules), puis cliquez sur `Create a new pipeline schedule`.

Vous allez pouvoir renseigner plusieurs champs :
- `Description` : un nom pour identifier la planification
- `Interval pattern` : la fréquence de déclenchement, au format cron (par exemple `0 2 * * *` pour tous les jours à 2h du matin)
- `Cron timezone` : le fuseau horaire à utiliser pour l'interprétation de l'intervalle
- `Target branch or tag` : la branche ou le tag sur lequel le pipeline sera déclenché
- `Variables` : des variables supplémentaires qui seront injectées dans le pipeline

> GitLab propose des raccourcis pour les intervalles les plus courants : `Every day`, `Every week`, `Every month`. Vous pouvez également utiliser une syntaxe cron personnalisée.

#### Différencier un pipeline planifié

Il peut être utile de savoir si un pipeline a été déclenché par une planification ou par un autre événement. La variable prédéfinie `CI_PIPELINE_SOURCE` permet de le savoir : sa valeur sera `schedule` pour un pipeline planifié.

Vous pouvez ainsi adapter le comportement de vos jobs :
```yaml
job-planifie-uniquement:
  stage: build
  script:
    - echo "Ce job ne s'exécute que lors des pipelines planifiés"
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"

job-hors-planification:
  stage: build
  script:
    - echo "Ce job ne s'exécute PAS lors des pipelines planifiés"
  rules:
    - if: $CI_PIPELINE_SOURCE != "schedule"
```

> Le mot-clé `rules` permet de définir des conditions pour l'exécution d'un job. Contrairement à `when`, il permet de contrôler l'ajout ou non d'un job au pipeline. Consultez la [documentation officielle](https://docs.gitlab.com/ci/yaml/#rules) pour en savoir plus.

#### Gestion des planifications

Une fois créée, vous pouvez gérer vos planifications depuis la page [`Build` > `Pipeline schedules`](http://gitlab/root/sample-project/-/pipeline_schedules). Vous pouvez les activer, les désactiver, les modifier ou les supprimer. Vous pouvez également déclencher manuellement un pipeline planifié en cliquant sur le bouton `Play`.

Créez une planification qui déclenche un pipeline toutes les heures, et ajoutez un job qui ne s'exécute que lors des pipelines planifiés.

> Consultez la [documentation officielle](https://docs.gitlab.com/ci/pipelines/schedules.html) pour plus d'informations sur les planifications.

## Conclusion

Félicitations, vous avez maintenant appris à utiliser les entrées utilisateur avec les inputs, à gérer les données sensibles avec les variables CI/CD et les secrets, à exécuter des actions avant et après les scripts avec `before_script` et `after_script`, et à planifier des pipelines avec les schedules.
