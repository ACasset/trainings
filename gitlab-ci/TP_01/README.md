# TP 01 : Vérifier l'état des runners et lancer un premier pipeline

## Introduction

Ce TP a pour but d'apprendre à :
- vérifier la présence de runners
- configurer un projet pour utiliser la CI/CD
- créer un pipeline basique

## Déroulé

### Consulter la liste des runners

En étant connecté à GitLab sous l'identité `root`, vous avez accès à la zone administrateur, et vous allez notamment pouvoir consulter la [page des runners](http://gitlab/admin/runners).

Sur cette dernière, vous allez constater la présence d'un runner au statut `Online`, avec le scope `Instance` : ce dernier point signifie que ces runners pourront être utilisés par l'ensemble des projets de l'instance GitLab. Il existe des scopes différents, restreignant les projets pouvant utiliser les runners : `Group` et `Project`.

En réalité, il s'agit d'un groupe de runners, qui sont regroupés car leur configuration est identique. En cliquant sur le `#1`, puis sur `Show details`, vous verrez apparaître 2 runners avec chacun son identifiant et son adresse IP.

### Configurer le projet

Ici, le script d'initialisation a créé un projet dans le namespace `root`, et on pourra y accéder avec l'URL suivante : http://gitlab/root/sample-project

> Si jamais vous utilisez un projet déjà existant sur votre propre instance de GitLab, vérifiez que la fonctionnalité `CI/CD` est activée, dans le menu `Settings` > `General` > `Visibility, project features, permissions`.

À partir de ce projet, il est possible de vérifier les runners disponibles, en allant dans [`Settings` > `CI/CD` > `Runners`](http://gitlab/root/sample-project/-/settings/ci_cd#js-runners-settings). Là, vous verrez les 3 scopes possibles, et vous constaterez que le groupe de runners d'instance est disponible pour le projet.

D'autre part, l'option `CI/CD configuration file` du menu [`Settings` > `CI/CD` > `General pipelines`](http://gitlab/root/sample-project/-/settings/ci_cd#js-general-pipeline-settings) permet de définir le nom du fichier d'entrée pour GitLab CI. Sauf contrainte particulière, il est recommandé de le laisser à sa valeur par défaut (`.gitlab-ci.yml`).

### Créer un fichier de pipeline basique

L'intégration de GitLab CI dans GitLab étant assez poussée, certains éléments de menu permettent d'accéder facilement aux fonctionnalités relatives aux pipelines, à travers le menu `Build`.

Nous allons maintenant créer un fichier de pipeline basique : rendez vous dans [`Build` > `Pipeline editor`](http://gitlab/root/sample-project/-/ci/editor), et cliquez sur `Configure pipeline`. GitLab va alors vous proposer un template, que nous n'allons pas modifier pour l'instant. Cliquez sur `Commit changes` en bas de l'écran.

Vous allez voir apparaître un `Pipeline #1 pending` en haut de l'écran, qui va assez vite se transformer en `Pipeline #1 running`. Le template ne fait rien de concret, mais il comporte des pauses, donc vous allez pouvoir suivre son déroulé.

Cliquez sur le `#1` pour afficher la vue du pipeline : vous allez ainsi pouvoir visualiser les 4 jobs, répartis en 3 stages. Leur exécution est séquentielle, et dépend de la clé `stages` de la configuration du pipeline (nous allons voir cela en détails juste après). Tous les jobs sont nécessairement rattachés à un stage, et, sauf instruction contraire, ils vont s'exécuter parallèlement au sein d'un même stage, ce que vous devriez constater dans le stage `test`.

> Chaque runner n'exécute, par défaut, qu'un seul job à un moment donné. Si il n'y avait eu qu'un seul runner, l'un des deux jobs du stage `test` se serait lancé au hasard en premier (pendant que l'autre aurait été au statut `pending`), et le second ne se serait exécuté qu'après la fin du premier.

Vous pouvez cliquer sur un job pour voir les logs qui lui sont propres, et éventuellement chercher une information spécifique, par curiosité ou afin de debug un pipeline en échec.

Le template ne faisant rien de concret (uniquement des `echo` et des `sleep`), celui-ci va s'exécuter jusqu'au bout sans erreurs.

### Explication du pipeline

Retournez maintenant dans le `Pipeline editor` via la barre latérale, et décortiquons le code.

Aux lignes 19 à 22, la première clé, `stages`, décrit la liste des stages de façon séquentielle : tous les jobs doivent mentionner un des éléments de cette liste, et celle-ci sera exécutée dans l'ordre.

Aux lignes 24 à 28, on trouve le premier job `build-job`, appartenant au premier stage `build`. La clé `script` contient les instructions shell qui vont être jouées sur le runner.

Aux lignes 30 à 42, on trouve les deux jobs suivants, appartenant au deuxième stage `test`.

Enfin, aux lignes 44 à 49, on trouve le dernier job, appartenant au stage `deploy`. Vous remarquerez la présence d'une clé supplémentaire : `environment`. Cette dernière permet de spécifier un environnement où l'application est supposément déployée. Vous pouvez retrouver l'environnement en question dans le menu [`Operate` > `Environments`](http://gitlab/root/sample-project/-/environments). Nous verrons dans un prochain TP les possibilités offertes par cette fonctionnalité.

## Conclusion

Félicitations, vous avez maintenant vu les bases de GitLab CI, et vous disposez d'un projet avec un pipeline basique qui s'exécute correctement.
