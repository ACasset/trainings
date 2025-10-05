# TP 02 : Contrôler l'exécution des jobs

## Introduction

Ce TP a pour but d'introduire les concepts suivants :
- les images
- les artifacts
- les services
- les variables
- les needs
- les when

## Déroulé

### Choix d'une image Docker

Lors du TP 01, nous avons utilisé le template de pipeline fourni par GitLab, qui utilise uniquement les instructions de base, et des commandes simples telles que `echo` et `sleep`, mais on peut imaginer facilement des cas de figure plus complexes, où on va vouloir par exemple compiler un programme C ou Java. Or, ces outils ne sont pas nécessairement installés dans l'image Docker utilisée par défaut.

Les jobs peuvent alors utiliser le mot-clé `image`, permettant de spécifier le nom d'une image Docker à utiliser, comme ceci :
```yaml
display-php-version:
  stage: test
  image: php:8.4.6-zts-alpine
  script:
    - php -v
```

Avec l'exemple ci-dessus, le runner GitLab CI va télécharger l'image `php:8.4.6-zts-alpine`, l'instancier, y copier le contenu du repository, et exécuter la commande `php -v`, qui va alors retourner (entre autres) `PHP 8.4.6 (cli) (built: Apr 11 2025 17:01:36) (ZTS)`. Si l'image n'avait pas été spécifiée, l'exécution aurait eu lieu sur l'image par défaut, le retour aurait été `php: not found`, et le job se serait terminé en erreur.

N'hésitez pas à rajouter le job susmentionné dans votre fichier `.gitlab-ci.yml` pour voir ce qu'il en ressort. En vous rendant dans les logs d'exécution du job, vous verrez notamment des instructions telles que `Using Docker executor with image php:8.4.6-zts-alpine`, `Pulling docker image php:8.4.6-zts-alpine` et `Using docker image sha256:[...] for php:8.4.6-zts-alpine with digest php@sha256:[...]`, indiquant que l'image a bien été identifiée, récupérée et utilisée.

> Si vous vous intéressez aux autres jobs pour lesquels nous n'avons pas spécifié d'image, vous vous apercevrez qu'ils utilisent tous l'image `docker:latest` par défaut. Ce comportement est personnalisable à plusieurs endroits, mais celui qui va vous intéresser est de renseigner la clé `image` à la racine du fichier `.gitlab-ci.yml` (plutôt que dans un job).

Chaque job est ainsi capable de s'exécuter dans une image différente, en sollicitant des binaires et des librairies différentes. En cas de besoin de différents binaires, il existe deux solutions :
- segmenter le pipeline pour que chaque besoin soit traité dans un job dédié avec une image spécifique, mais cela n'est pas toujours possible, auquel cas vous devrez...
- construire votre propre image Docker contenant tous les binaires, et la mettre à disposition du runner GitLab CI

> Il est fortement déconseillé d'installer à la volée des binaires sur les conteneurs (par exemple, inclure un `microdnf install php` dans l'instruction `script`), car cela entraînera tôt ou tard des problèmes de compatibilité entre les versions utilisées. Privilégiez plutôt l'utilisation du tag `latest` des images.

Que vous utilisiez une image Docker tierce ou que vous construisiez la vôtre, les seules conditions sont qu'elle doit disposer de `bash` (ou de `sh`) et de `grep`.

> Vous pouvez en apprendre plus dans [la documentation officielle](https://docs.gitlab.com/ci/docker/using_docker_images/).

Le périmètre de ces TPs concerne cependant l'utilisation de GitLab CI, et pas la création d'images Docker : nous allons donc chercher à toujours utiliser des images disponibles publiquement, et donc segmenter le pipeline comme évoqué plus tôt.

### Transmission de données et de fichiers d'un job à l'autre

Imaginons maintenant que notre projet ait besoin de récupérer des informations avec `curl` avant de lancer ses tests. Ce dernier n'est pas présent dans l'image de base `docker:latest`. Rajoutez donc un job avec une image dédiée pour cela :
```yaml
get-wordpress-salts:
  stage: build
  image: curlimages/curl:8.13.0
  script:
    - echo "<?php" > wordpress_salts.php
    - curl --silent https://api.wordpress.org/secret-key/1.1/salt/ >> wordpress_salts.php
    - echo "?>" >> wordpress_salts.php
    - cat wordpress_salts.php
```

Vous verrez dans le log d'exécution du job que le `cat` renvoie bien un fichier correctement constitué, mais le job s'exécutant de façon isolée dans un conteneur, il n'est pas possible de réutiliser ce fichier dans un autre job. Nous allons devoir utiliser un nouveau concept : les `artifacts`.

Un artifact est un __fichier__ produit par un job, et qui va être mis à disposition des autres jobs. Dans notre cas, notre retour est déjà placé dans un fichier, donc on va pouvoir simplement déclarer ce fichier en tant qu'artifact comme suit :
```yaml
get-wordpress-salts:
  stage: build
  image: curlimages/curl:8.13.0
  script:
    - echo "<?php" > wordpress_salts.php
    - curl --silent https://api.wordpress.org/secret-key/1.1/salt/ >> wordpress_salts.php
    - echo "?>" >> wordpress_salts.php
    - cat wordpress_salts.php
  artifacts:
    paths:
      - wordpress_salts.php
```

> Si on veut transmettre autre chose qu'un fichier, par exemple le contenu d'une variable, il faudra passer par l'étape de placer le contenu de la variable dans un fichier, et de déclarer ce dernier comme artifact.

Si vous appliquez cette modification et que vous vous rendez dans le job `get-wordpress-salts`, vous verrez un nouveau bloc `Job artifacts` sur la droite, qui vous permet entre autres de télécharger le fichier `wordpress_salts.php` fraîchement créé.

Vous pouvez maintenant modifier le job `display-php-version` pour y ajouter l'affichage du fichier :
```yaml
display-php-version:
  stage: test
  image: php:8.4.6-zts-alpine
  script:
    - php -v
    - cat wordpress_salts.php
```

> Dans notre cas, rien de plus n'est nécessaire car les deux jobs sont dans des stages différents. Nous allons voir plus tard comment faire au sein d'un même stage.

### Utilisation de services

Imaginons maintenant que vous ayez une application un peu plus complexe à disposition : du PHP sollicitant une base de données PostgreSQL et un Redis. Le fait d'installer tous ces outils sur une seule image présente un problème de complexité, et de représentativité. En effet, avoir tous les services dans un seul conteneur ne reflètera pas le contexte d'exécution en production.

GitLab CI propose pour cet usage le mot-clé `services`. Ce dernier permet de créer un conteneur exécuté en parallèle du job, pour, par exemple, peupler une base de données PostgreSQL et faire une série de tests unitaires.

> Attention, comme les services sont exécutés en parallèle, ils sont accessibles par les protocoles réseau standards, mais pas via l'instruction `script` des jobs.

Pour vous en servir, ajoutez la liste des images que vous souhaitez au job comme suit :
```yaml
try-database-connection:
  stage: test
  image: php:8.4.6-zts-alpine
  services:
    - postgres:16.8-alpine3.20
  script:
    # Le service sera accessible sur le hostname correspondant au nom de son image
    - ping -c 4 postgres
```

Vous allez constater que les logs de ce job annoncent maintenant le lancement du service (`Starting service postgres:16.8-alpine3.20`), la récupération de l'image Docker (`Pulling docker image postgres:16.8-alpine3.20`), et l'attente que le service soit disponible (`Waiting for services to be up and running (timeout 30 seconds)`).

Malheureusement, dans notre cas, cela va échouer. En effet, dans dans le cas de l'image `postgres` (et d'autres), la simple instanciation de l'image Docker ne suffit pas. Il va donc falloir suivre [le guide d'utilisation de cette image](https://hub.docker.com/_/postgres/), et initialiser proprement la base de données en lui passant _a minima_ la variable `POSTGRES_PASSWORD` comme suit :
```yaml
try-database-connection:
  stage: test
  image: php:8.4.6-zts-alpine
  services:
    - postgres:16.8-alpine3.20
  variables:
    POSTGRES_PASSWORD: "V3ryS3cur3P@ssw0rd!"
  script:
    - ping -c 4 postgres
    # Le mot de passe ayant été déclaré comme variable, on peut également l'utiliser ici
    - echo Mot de passe PostgreSQL = ${POSTGRES_PASSWORD}
```

Nous avons ici placé la clé `variables` au sein du job, donc seul ce job pourra utiliser cette variable. Cela fait sens dans notre cas de figure : le service est déclaré dans le job, donc seul ce dernier y aura accès.

> Les services sont réinitialisés pour chaque job : il n'est ainsi pas possible d'avoir un premier job qui initialise un service, et un autre qui va simplement l'utiliser.

Si on imagine que plusieurs jobs vont utiliser le même service, ou les mêmes variables, on peut placer les mots-clés correspondants à la racine du fichier `.gitlab-ci.yml` comme suit :
```yaml
services:
  - postgres:16.8-alpine3.20

variables:
  POSTGRES_PASSWORD: "V3ryS3cur3P@ssw0rd!"

try-database-connection:
  stage: test
  image: php:8.4.6-zts-alpine
  script:
    - ping -c 4 postgres
    # La variable est déclarée à la racine du fichier '.gitlab-ci.yml', donc on y a toujours accès
    - echo Mot de passe PostgreSQL = ${POSTGRES_PASSWORD}
```

> Dans notre cas, cela signifie que tous les jobs vont lancer un service postgres, y compris ceux qui ne le sollicitent pas. Cela n'aura pas d'impact en soi sur leur exécution, mais cela charge inutilement les runners.

Enfin, vous pouvez vouloir personnaliser différents paramètres des services, tout particulièrement s'il s'agit d'une image atypique ou que vous avez vous-même construite. Vous pouvez alors utiliser un dictionaire comme suit :
```yaml
services:
  - name: postgres:16.8-alpine3.20
    alias: db
    # On conserve l'entrypoint de l'image
    entrypoint: ["docker-entrypoint.sh"]
    # Ainsi que sa commande
    command: ["postgres"]
    variables:
      POSTGRES_PASSWORD: "V3ryS3cur3P@ssw0rd!"

try-database-connection:
  stage: test
  image: php:8.4.6-zts-alpine
  script:
    # Comme on a spécifié un alias, on peut maintenant joindre le service en l'utilisant
    - ping -c 4 db
    # Les variables étant maintenant spécifiées dans le service, on y a plus accès au sein du job même et le retour de la variable sera vide
    - echo Mot de passe PostgreSQL = ${POSTGRES_PASSWORD}
```

> Comme toujours, n'hésitez pas à lire [la documentation officielle](https://docs.gitlab.com/ci/services/) sur le sujet.

### Ordonnancement des différents jobs

Lors du TP 01, nous avons utilisé le template de pipeline fourni par GitLab, qui permet de faire un séquençage basique des jobs avec les stages. Mais une des grandes forces des pipelines est de pouvoir adapter leur comportement et leur déroulé en fonction de différents paramètres.

Pour commencer, imaginons que nous ayons besoin, au sein d'un même stage, d'ordonner le séquençage des jobs. Le mot-clé `needs` répond à ce besoin, en listant simplement les jobs qui doivent s'être exécutés avant. Mettons en place une chaîne de dépendance pour le stage `test` :
```yaml
unit-test-job:   # This job runs in the test stage.
  stage: test    # It only starts when the job in the build stage completes successfully.
  script:
    - echo "Running unit tests... This will take about 60 seconds."
    - sleep 60
    - echo "Code coverage is 90%"
  needs:
    - lint-test-job

lint-test-job:   # This job also runs in the test stage.
  stage: test    # It can run at the same time as unit-test-job (in parallel).
  script:
    - echo "Linting code... This will take about 10 seconds."
    - sleep 10
    - echo "No lint issues found."

display-php-version:
  stage: test
  image: php:8.4.6-zts-alpine
  script:
    - php -v
    - cat wordpress_salts.php
  needs:
    - get-wordpress-salts
    - unit-test-job

try-database-connection:
  stage: test
  image: php:8.4.6-zts-alpine
  script:
    - ping -c 4 db
    - echo Mot de passe PostgreSQL = ${POSTGRES_PASSWORD}
  needs:
    - display-php-version
```

Si vous vous rendez dans la vue du pipeline, vous verrez un nouvel entête `Group jobs by`, sur lequel vous pourrez sélectionner l'option `Job dependencies` pour matérialiser la chaîne de dépendance que nous venons de mettre en oeuvre.

> `needs` est le mécanisme permettant d'utiliser des artifacts au sein d'un même stage : un job donné mettra ses artifacts à disposition du job qui le liste dans ses `needs`.

Cependant, vous allez constater que le job `display-php-version` du pipeline va échouer, car il ne trouve plus le fichier `wordpress_salts.php`. En effet, le fait de renseigner le mot-clé `needs` entraîne la conséquence que le job ne télécharge plus tous les artifacts des stages précédents par défaut. Corrigez donc les `needs` pour que l'artifact soit à nouveau disponible dans le job `display-php-version`.

### Contrôle de l'exécution ou non d'un job

Maintenant, disons que l'on souhaite être averti de la réussite ou de l'échec du déploiement. Le mot-clé `when` permet de répondre à ce besoin.

TODO

> Lorsqu'il n'est pas renseigné, ce mot-clé est en réalité appliqué avec sa valeur `on_success`.

## Conclusion

TBD
