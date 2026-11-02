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
      type: number
      regex: 
      options: ['build', 'test', 'deploy']
string (default when not specified), array, number, or boolean
```

> Les valeurs possibles de `type` sont : `string` (valeur par défaut), `array`, `number` et `boolean`.

> Comme d'habitude, pour en savoir plus, consultez la [documentation officielle](https://docs.gitlab.com/ci/inputs/)

### Utilisation de données sensibles

TBD

### Exécution d'actions antérieures et postérieures aux scripts

TBD

### Planification de pipelines

TBD

## Conclusion

TBD
