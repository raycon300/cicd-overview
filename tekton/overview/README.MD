# Pré requisitos

- O operador OpenShift Pipelines deve estar instalado no cluster no namespace `openshift-operators`.
- Criar o projeto `empresa-cicd` no cluster.
- [tkn CLI](https://tekton.dev/docs/cli/) instalado e configurado para o cluster.

# Tasks

## Criando uma Task simpes

```bash 
cd overview/tasks
```

```bash
oc create -n empresa-cicd  -f primeiratask.yaml
```

Podemos ver a task criada com um dos comandos:

```bash
oc get tasks -n empresa-cicd
```

``` bash
NAME                          AGE
primeira-task                 20m
```

```bash
tkn task ls -n empresa-cicd
```

```bash
NAME                          DESCRIPTION   AGE
primeira-task                               19 minutes ago
```

Vamos executar a task com o comando:

```bash
tkn task start primeira-task -n empresa-cicd --showlog
```

Caso seja necessário podemos obter os detalhes sobre a execução da task com os comandos:

```bash
tkn taskrun ls -n empresa-cicd
```

```bash
NAME                                    STARTED          DURATION   STATUS
primeira-task-run-vtzmn                 20 minutes ago   22s        Succeeded
```

```bash
tkn taskrun describe primeira-task-run-vtzmn -n empresa-cicd
```

```bash
Name:              primeira-task-run-vtzmn
Namespace:         empresa-cicd
Task Ref:          primeira-task
Service Account:   pipeline
Timeout:           1h0m0s
Labels:
 app.kubernetes.io/managed-by=tekton-pipelines
 tekton.dev/task=primeira-task
Annotations:
 chains.tekton.dev/signed=true
 pipeline.tekton.dev/release=c8ef1db

🌡️  Status

STARTED          DURATION    STATUS
26 minutes ago   22s         Succeeded

🦶 Steps

 NAME      STATUS
 ∙ start   Completed
```


## Criando uma Task com multiplas etapas

```bash
oc create -n empresa-cicd -f multiplas-etapas.yaml
```

Vamos validar a criação da task com um dos comandos abaixo:

```bash
oc get -n empresa-cicd tasks
```

```bash
tkn task ls -n empresa-cicd
```

Vamos executar a task com o comando:

```bash
tkn task start multiplas-etapas --showlog -n empresa-cicd
```

Se fizermos um `oc get pods` vamos ver que a task criou um pod para cada etapa da task.

```bash
oc get pods -n empresa-cicd
```

```bash
NAME                                        READY   STATUS      RESTARTS   AGE
multiplas-etapas-run-72xld-pod              0/2     Completed   0          7h
```

## Criando uma Task com multiplas etapas executando um script em uma delas

```bash
oc create -n empresa-cicd -f multiplas-etapas-com-script.yam
```

Vamos executar a task com o comando:

```bash
tkn task start multiplas-etapas-com-script --showlog -n empresa-cicd
```

Vamos ver os detalhes da execução da TaskRun:

```bash
tkn tr ls -n empresa-cicd
```

```bash
NAME                                    STARTED          DURATION   STATUS
multiplas-etapas-com-script-run-n5sk7   14 minutes ago   27s        Succeeded
```

```bash
Name:              multiplas-etapas-com-script-run-n5sk7
Namespace:         empresa-cicd
Task Ref:          multiplas-etapas-com-script
Service Account:   pipeline
Timeout:           1h0m0s
Labels:
 app.kubernetes.io/managed-by=tekton-pipelines
 tekton.dev/task=multiplas-etapas-com-script
Annotations:
 chains.tekton.dev/signed=true
 pipeline.tekton.dev/release=c8ef1db

🌡️  Status

STARTED          DURATION    STATUS
17 minutes ago   27s         Succeeded

🦶 Steps

 NAME                    STATUS
 ∙ primeira              Completed
 ∙ segunda               Completed
 ∙ terceira-com-script   Completed
```
Tambem podemos rever os logs de execução da TaskRun com o comando:

```bash
tkn tr logs multiplas-etapas-com-script-run-n5sk7 -n empresa-cicd
```

```bash
[primeira] Primeira Etapa executando

[segunda] Segunda Etapa executando

[terceira-com-script] #### Installando tools ####
[terceira-com-script] Updating Subscription Management repositories.
...
[terceira-com-script] ### Finalizando a terceira etapa ###
```

## Adicionando um parâmetro a uma Task

```bash
oc create -n empresa-cicd -f task-com-parametro.yaml
```

Primeiro vamos executar a task sem passar o parametro `mensagem` _(o tkn vai entrar no modo iterativo e perguntar o valor para o parâmetro)_:

```bash
tkn task start task-com-parametro --showlog -n empresa-cicd
? Value for param `mensagem` of type `string`? (Default is `Hello World`) (Hello World)
```
Podemos executar a task passando o valor do parametro `mensagem` _(nessa caso o tkn não vai perguntar pelo valor do parâmetro mensagem)_:


```bash
tkn task start task-com-parametro --showlog -n empresa-cicd -p mensagem="Olá Mundo"
```

Podemos ver os detalhes da execução da TaskRun com os comandos:

```bash
tkn tr ls -n empresa-cicd
```

```bash
NAME                                    STARTED          DURATION   STATUS
task-com-parametro-run-f22wd            12 seconds ago   4s         Succeeded
```

```bash
tkn tr describe task-com-parametro-run-f22wd -n empresa-cicd
```

```bash
Name:              task-com-parametro-run-f22wd
Namespace:         empresa-cicd
Task Ref:          task-com-parametro
Service Account:   pipeline
Timeout:           1h0m0s
Labels:
 app.kubernetes.io/managed-by=tekton-pipelines
 tekton.dev/task=task-com-parametro
Annotations:
 chains.tekton.dev/signed=true
 pipeline.tekton.dev/release=c8ef1db

🌡️  Status

STARTED          DURATION    STATUS
29 seconds ago   4s          Succeeded

⚓ Params

 NAME         VALUE
 ∙ mensagem   Olá Mundo # (1) parâmetro passado na execução da task

🦶 Steps

 NAME               STATUS
 ∙ print-mensagem   Completed
```

## Passando pequenas informações de uma task para outra usando Results

Para passar *pequenas* informações de uma task para outra podemos usar o recurso de Results do Tekton.
> O recurso de Results do Tekton é limitado a 1MB de dados.
> Podemos usar o conceito de Workspaces para passar informações maiores entre as tasks.

```bash
oc create -n empresa-cicd -f task-results.yaml
```

Vamos executar a task com o comando:

```bash
tkn task start task-results --showlog -n empresa-cicd
```

```bash
TaskRun started: task-results-run-g77hl
Waiting for logs to be available...
[exibir-mensagem-antes-de-codificar-em-base64] Primeira Etapa executando

[escrever-mensagem] encode msg Primeira Etapa executando ...

[ler-mensagem] UHJpbWVpcmEgRXRhcGEgZXhlY3V0YW5kbwo= # (1) resultado da execução da task anterior
```

Podemos ver os results utilizando o `tkn describe` Na taskRun:

```bash
tkn tr ls -n empresa-cicd
```

```bash
NAME                                    STARTED          DURATION   STATUS
task-results-run-w9ms4                  1 minute ago     7s         Succeeded
```

```bash
tkn tr describe task-results-run-w9ms4 -n empresa-cicd
```

```bash
Name:              task-results-run-w9ms4
Namespace:         empresa-cicd
Task Ref:          task-results
Service Account:   pipeline
Timeout:           1h0m0s
Labels:
 app.kubernetes.io/managed-by=tekton-pipelines
 tekton.dev/task=task-results
Annotations:
 chains.tekton.dev/signed=true
 pipeline.tekton.dev/release=c8ef1db

🌡️  Status

STARTED        DURATION    STATUS
1 minute ago   7s          Succeeded

📝 Results

 NAME         VALUE
 ∙ mensagem   UHJpbWVpcmEgRXRhcGEgZXhlY3V0YW5kbwo= # (1) resultado da execução da task anterior

🦶 Steps

 NAME                                             STATUS
 ∙ exibir-mensagem-antes-de-codificar-em-base64   Completed
 ∙ escrever-mensagem                              Completed
 ∙ ler-mensagem                                   Completed
```

## Passando informações de uma task para outra usando Volumes - ConfigMaps

Podemos usar Volumes para passar informações para uma task. Podem montar um ConfigMap como volume em uma task e ler as informações do ConfigMap.

Primeiro precisamos criar o ConfigMap

```bash
oc create -n empresa-cicd configmap mapa-de-cores \
    --from-literal=error="\e[31m" \
    --from-literal=warning="\e[32m" \
    --from-literal=info="\e[34m"
```
Vamos ver o configmap que foi criado:
```bash
oc get cm mapa-de-cores -o yaml -n empresa-cicd | yq
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mapa-de-cores
  namespace: empresa-cicd
data:
  error: \e[31m
  info: \e[34m
  warning: \e[32m
```

Agora vamos criar a task que vai ler as informações do ConfigMap:

```bash
oc apply -f task-ler-configmap.yaml -n empresa-cicd
```

Vamos executar a task com o comando:

```bash
tkn task start ler-configmap -n empresa-cicd --showlog
```

```bash
TaskRun started: ler-configmap-run-h8bqj
Waiting for logs to be available...
[imprimir-cores-do-configmap] #### Listando cores do ConfigMap ####
[imprimir-cores-do-configmap] total 0
[imprimir-cores-do-configmap] lrwxrwxrwx. 1 root 1000700000 12 Jul 28 00:40 error -> ..data/error
[imprimir-cores-do-configmap] lrwxrwxrwx. 1 root 1000700000 11 Jul 28 00:40 info -> ..data/info
[imprimir-cores-do-configmap] lrwxrwxrwx. 1 root 1000700000 14 Jul 28 00:40 warning -> ..data/warning
...
```

# Pipelines

Depois que entendemos como funcionam as Tasks fica simples entender uma Pipeline no Tekton.

Uma Pipeline é uma sequência de Tasks que são executadas em uma ordem específica.


## Criando uma Pipeline simples

Sendo uma Pipeline uma sequência de Tasks, vamos primeiro ver a nossa lista de Tasks.

```bash
tkn task ls -n empresa-cicd
```

```bash
NAME                          DESCRIPTION   AGE
ler-configmap                               22 minutes ago
multiplas-etapas                            8 hours ago
multiplas-etapas-com-script                 8 hours ago
primeira-task                               8 hours ago
task-com-parametro                          1 hour ago
task-results                                52 minutes ago
```

Vamos criar a Pipeline como descrito no arquivo `primeirapipeline.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: primeira-pipeline       # (1) nome da pipeline
spec:
  tasks:                        # (2) lista de tasks que vão ser executadas

    - name: imprimir-hello      # (3) nome da task
      taskRef:
          name: primeira-task   # (4) nome da task que vai ser executada
```

Vamos criar a Pipeline com o comando:

```bash
cd pipe
```

```bash
oc create -n empresa-cicd -f primeirapipeline.yaml
```

Agora vamos executar a Pipeline com o comando:

```bash
tkn pipeline start primeira-pipeline -n empresa-cicd --showlog
```

Vamos ver os detalhes da execução da Pipeline com o comando:

```bash
#listar pipeline runs

tkn pipelinerun ls -n empresa-cicd
```

```bash
NAME                          STARTED          DURATION   STATUS
primeira-pipeline-run-mxzt5   14 seconds ago   4s         Succeeded
```

```bash
tkn pr describe primeira-pipeline-run-mxzt5 -n empresa-cicd # pr é um alias para pipelinerun
```

```bash
Name:              primeira-pipeline-run-mxzt5
Namespace:         empresa-cicd
Pipeline Ref:      primeira-pipeline
Service Account:   pipeline
Labels:
 tekton.dev/pipeline=primeira-pipeline
Annotations:
 chains.tekton.dev/signed=true

🌡️  Status

STARTED          DURATION   STATUS
54 seconds ago   4s         Succeeded

⏱  Timeouts
 Pipeline:   1h0m0s

🗂  Taskruns

 NAME                                           TASK NAME        STARTED          DURATION   STATUS
 ∙ primeira-pipeline-run-mxzt5-imprimir-hello   imprimir-hello   54 seconds ago   4s         Succeeded
```

## Passando parâmetros para Pipeline

Podemos passar parâmetros para uma Pipeline da mesma forma que passamos parâmetros para uma Task.

Esses parâmetros podem ser usados para configurar as Tasks que vão ser executadas pela Pipeline.

Vamos criar a Pipeline como descrito no arquivo `pipeline-com-parametro.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: pipeline-com-parametro
spec:
  params:
    - name: texto-boas-vindas   # (1) nome do parâmetro que vai ser passado para a pipeline
      type: string
      default: "Fala comigo!"   # (2) valor padrão do parâmetro caso não seja passado na execução da pipeline
      description: Mensagem de boas vindas

  tasks:
    - name: imprimir-hello
      taskRef:
          name: primeira-task

    - name: imprimir-ola
      params:
        - name: mensagem        # (3) nome do parâmetro definido na task que vai ser executada (veja arquivo tasks/task-com-parametro.yaml)
          value: "$(params.texto-boas-vindas)" # (4) valor do parâmetro que vai ser passado para a task
      taskRef:
          name: task-com-parametro
```

Vamos criar a Pipeline com o comando:

```bash
oc create -n empresa-cicd -f pipeline-com-parametro.yaml
```

Agora vamos executar a Pipeline com o comando:

```bash
tkn pipeline start pipeline-com-parametro -n empresa-cicd --showlog
```

Como não passamos o parâmetro `texto-boas-vindas` na execução da Pipeline, o tkn vai entrar no modo iterativo e perguntar o valor para o parâmetro:

```bash
? Value for param `texto-boas-vindas` of type `string`? (Default is `Fala comigo!`) Fala comigo!
```

```bash
PipelineRun started: pipeline-com-parametro-run-zcsj2
Waiting for logs to be available...
[imprimir-hello : start] Hello World

[imprimir-ola : print-mensagem] Fala comigo!
```

Podemos passar o valor do parâmetro `texto-boas-vindas` na execução da Pipeline com o comando:

```bash
tkn pipeline start pipeline-com-parametro -n empresa-cicd --showlog -p texto-boas-vindas="Olá Mundo"
```

```bash
# Por padrão as Tasks são executadas em paralelo, por isso na saída abaixo a task imprimir-ola foi executada antes da task imprimir-hello 
PipelineRun started: pipeline-com-parametro-run-p92lp
Waiting for logs to be available...
[imprimir-ola : print-mensagem] Olá Mundo   
[imprimir-hello : start] Hello World
```

## Ordem de execução das Tasks em uma Pipeline

Por padrão as Tasks são executadas em paralelo, mas podemos definir a ordem de execução das Tasks usando o recurso de `runAfter` do Tekton.

Vamos criar a Pipeline como descrito no arquivo `pipeline-com-ordem-de-execucao.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: pipeline-com-ordem-de-execucao
spec:
  params:
    - name: texto-boas-vindas
      type: string
      default: "Fala comigo!"
      description: Mensagem de boas vindas

  tasks:
    - name: imprimir-hello
      taskRef:
          name: primeira-task

    - name: imprimir-ola
      params:
        - name: mensagem
          value: "$(params.texto-boas-vindas)"
      runAfter:             # (1) lista de tasks que vão ser executadas antes da task atual
        - imprimir-hello    # (2) quando a task imprimir-hello terminar a task imprimir-ola vai ser executada
      taskRef:
          name: task-com-parametro
```

Vamos criar a Pipeline com o comando:

```bash
oc apply -f pipeline-com-ordem-de-execucao.yaml -n empresa-cicd
```

Agora vamos executar a Pipeline com o comando:

```bash
tkn pipeline start pipeline-com-ordem-de-execucao -n empresa-cicd --showlog -p texto-boas-vindas="Olá Mundo Ordenado"
```

```bash
# Agora a task imprimir-ola só vai ser executada depois que a task imprimir-hello terminar

PipelineRun started: pipeline-com-ordem-de-execucao-run-mpm78
Waiting for logs to be available...
[imprimir-hello : start] Hello World

[imprimir-ola : print-mensagem] Olá Mundo Ordenado
```
No vscode com o plugin `Tekton Pipelines` é possível ver a ordem de execução das tasks em uma Pipeline. Basta selecionar o arquivo da Pipeline e e usar o atalho `command + shift + p` (Mac) ou `ctrl + shift + p` (windows) e digitar `Open Pipeline preview to the Side` e um gráfico será exibido.

## Usando Finalizers em uma Pipeline

Podemos usar o recurso de Finalizers para definir uma lista de Tasks que vão ser executadas depois que todas as Tasks da Pipeline terminarem.


Vamos criar a Pipeline como descrito no arquivo `pipeline-com-finalizers.yaml`:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: pipeline-com-finalizers
spec:
  params:                             # (1) parâmetros da pipeline que vão ser passados para as tasks
    - name: exit-code
      description: Código de saída da task
      default: "0"
      type: string
  tasks:
    - name: inline-task
      params:
        - name: exit
          value: "$(params.exit-code)" # (2) valor do parâmetro que vai ser passado para a task
      taskSpec:                        # (3) inline task - não precisa criar um arquivo com a task, mas não é possível reutilizar a task
        params:
          - name: exit                 # (4) parâmetro de entrada da task
            description: Código de saída da task
            default: "0"
            type: string
        steps:
          - name: inline-taks
            image: registry.access.redhat.com/ubi8/ubi
            script: |
              echo "Executando inline task"
              exit $(params.exit)       

  finally:
    - name: send-notification
      when:                            # (5) vamos utilizar o condicional [when] para determinar quando executar a task
        - input: $(tasks.inline-task.status)
          operator: notin
          values:
            - "Failed"                 # (6) quando a task inline-task NÃO terminar com status [Failed] a task send-notification vai ser executada
      taskSpec:
        steps:
          - name: send-email
            image: registry.access.redhat.com/ubi8/ubi
            script: |
              echo "Enviando email de notificação"

    - name: notification-error
      when:
        - input: $(tasks.inline-task.status)
          operator: in
          values:
            - "Failed"                 # (7) quando a task inline-task terminar com status [Failed] a task notification-error vai ser executada
      taskSpec:
        steps:
          - name: log-error
            image: registry.access.redhat.com/ubi8/ubi
            script: |
              echo "Erro ao executar pipeline"
```
> Nota: Utilizar `taskSpec` inline não é uma boa prática, pois não é possível reutilizar a task em outras pipelines. 🫣 


Vamos criar a Pipeline com o comando:

```bash
oc apply -f pipeline-com-finalizers.yaml -n empresa-cicd
```

E vamos testar a execução da Pipeline do caso de sucesso onde a Task `send-notification` vai ser executada:

```bash
tkn pipeline start pipeline-com-finalizers -n empresa-cicd --showlog -p exit-code="0"
```

```bash
PipelineRun started: pipeline-com-finalizers-run-n4zzk
Waiting for logs to be available...
[inline-task : inline-taks] Executando inline task

[send-notification : send-email] Enviando email de notificação
```

Agora vamos testar a execução da Pipeline do caso de erro onde a Task `notification-error` vai ser executada:


```bash
tkn pipeline start pipeline-com-finalizers --showlog -p exit-code=1
```

```bash
[inline-task : inline-taks] Executando inline task

failed to get logs for task inline-task : container step-inline-taks has failed  : [{"key":"StartedAt","value":"2023-07-28T17:10:13.136Z","type":3}]

[notification-error : log-error] Erro ao executar pipeline
```

## Conceitualizando Workspaces

`Workspaces` são `Volumes` compartilhados que podem ser utilizados para trafegar dados entre steps de uma Task ou entre as várias Tasks de uma Pipeline.<br>
Os Volumes que são montados em um Workspace são chamados de `VolumeSources`.<br>
O VolumeSource pode ser um `ConfigMap`, `Secret`, `PersistentVolumeClaim` ou `EmptyDir`.<br>

Vamos entender um pouco sobre os vários tipos de VolumeSources que podemos usar em um Workspace:

- `EmptyDir` - É criado e destruído junto com a Task _(Pod)_ que está executando e não pode ser utilizado para compartilhar informações entre Tasks de uma Pipeline _(pode ser usado para compartilhar dados entre steps de uma Task)_.

- `ConfigMap` - Podemos montá-los como Volume em um Workspace. Seu conteúdo vai estar disponível como _read-only_.

- `Secret` - Pode ser configurado como VolumeSource em um Workspace. Assim como o ConfigMap seu conteúdo vai estar disponível como _read-only_.


- `PersistentVolumeClaim` e `VolumeClaimTemplate` - Permite que uma pasta seja montada e compartilha entre Tasks. O conteúdo do Volume vai estar disponível como _read-write_.

> Nota: Preferencialmente devemos usar VolumeClaimTemplate para criar o PersistentVolumeClaim pois o VolumeClaimTemplate é destruído junto com a TaskRun ou PipelineRun em que ele foi atachado. 
<br>Se usarmos o PersistentVolumeClaim ele vai ser criado e não vai ser destruído quando a TaskRun ou PipelineRun for deletada. Isso significa que:
<br><br> A) Se a Pipeline for executada novamente o PersistentVolumeClaim vai ser montado novamente e o conteúdo do Volume ainda vai estar disponível para as Tasks _(isso pode ser um problema)_.
<br><br>B) Para evitar o problema mencionado anteriormente precisamos garantir que o conteúdo do PersistentVolumeClaim seja apagado utilizando um finalizer.

## Criando uma Pipeline com um Workspace - EmptyDir

Vamos criar uma Pipeline que vai usar um Workspace do tipo EmptyDir.

Para isso vamos primeiro criar uma Task que vai clonar um projeto público do github para um Workspace.

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: git-clone-and-list
spec:
  params:
    - name: repositorio             # (1) parâmetro que vai ser passado para a task
      type: string
      description: Repositório a ser clonado
      default: "https://github.com/raycon300/poc-devops-php"

  workspaces:                       # (2) lista de workspaces que vão ser usados pela task
    - name: source
      description: Local onde o código será clonado

  steps:
    - name: clone
      image: alpine/git
      workingDir: $(workspaces.source.path) # (3) o diretório de trabalho da task vai ser o diretório do workspace
      command:
        - /bin/sh
      args:
        - -c
        - git clone -v $(params.repositorio) ./source-files # (4) clonando o repositório para um folder source-files no workspace

    - name: list
      image: alpine
      workingDir: $(workspaces.source.path) # (5) o diretório de trabalho da task vai ser o diretório do workspace (o mesmo da task anterior)
      command:
        - /bin/sh
      args:
        - -c
        - ls -l ./source-files      # (6) listando o conteúdo que foi adicionado no folder source-files na task anterior
```

Para criar a Task vamos utilizar o comando:

```bash
oc apply -f git-clone-and-list.yaml -n empresa-cicd
```

Agora vamos executar a Task, o tkn vai nos perguntar o valor para o workspace `source`:


```bash
tkn task start git-clone-and-list -n empresa-cicd --showlog -p repositorio=https://github.com/raycon300/poc-devops-php
```
```bash
Please give specifications for the workspace: source
? Name for the workspace : source
? Value of the Sub Path :           # pressione enter
? Type of the Workspace : emptyDir
? Type of EmptyDir :                # pressione enter
```

```bash
TaskRun started: git-clone-and-list-run-s987h
Waiting for logs to be available...
[clone] Cloning into './source'...
[clone] POST git-upload-pack (175 bytes)
[clone] POST git-upload-pack (217 bytes)

[list] total 2296
[list] -rw-r--r--    1 root     10007000        25 Jul 28 19:43 README.md
[list] -rwxr-xr-x    1 root     10007000   1104787 Jul 28 19:43 background.png
[list] -rw-r--r--    1 root     10007000   1036752 Jul 28 19:43 background2.png
[list] -rwxr-xr-x    1 root     10007000      5430 Jul 28 19:43 book.ico
[list] -rwxr-xr-x    1 root     10007000    121265 Jul 28 19:43 bootstrap.min.css
[list] -rwxr-xr-x    1 root     10007000     36874 Jul 28 19:43 bootstrap.min.js
[list] -rwxr-xr-x    1 root     10007000       205 Jul 28 19:43 config.ini
[list] -rwxr-xr-x    1 root     10007000      3040 Jul 28 19:43 cover.css
[list] drwxr-sr-x    2 root     10007000       195 Jul 28 19:43 data
[list] -rwxr-xr-x    1 root     10007000       534 Jul 28 19:43 ie10-viewport-bug-workaround.css
[list] -rwxr-xr-x    1 root     10007000       664 Jul 28 19:43 ie10-viewport-bug-workaround.js
[list] -rwxr-xr-x    1 root     10007000      3286 Jul 28 19:43 index.php
[list] -rwxr-xr-x    1 root     10007000      2825 Jul 28 19:43 prefs.php
[list] -rw-r--r--    1 root     10007000        14 Jul 28 19:43 texte.txt
```

Podemos analisar o `TaskRun` que foi criado pelo tkn para entendermos melhor o que aconteceu:


```bash
tkn  tr describe git-clone-and-list-run-s987h -o yaml
```

```yaml
# algumas partes foram omitidas para facilitar a leitura
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: git-clone-and-list-run-s987h
  namespace: empresa-cicd
spec:
  params:
    - name: repositorio
      value: https://github.com/raycon300/poc-devops-php
  taskRef:
    kind: Task
    name: git-clone-and-list
  workspaces:               # (1) lista de workspaces que foram criados para a execução da task
    - emptyDir: {}
      name: source
```

Podemos executar a Task novamente passando o valor do workspace `source` na execução da Task:

```bash
tkn task start git-clone-and-list -n empresa-cicd --showlog \
    -p repositorio=https://github.com/raycon300/poc-devops-php \
    -w name=source,emptyDir=""  # (1) passando o valor do workspace source na execução da task
```

Mas ainda estamos rodando a Task e o que queremos é criar uma Pipeline que vai executar a Task e passar o valor do workspace `source` para a Task.

Primeiro vamos separar a Task em duas Tasks, uma para clonar o repositório no workspace e outra para listar o conteúdo do workspace:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: git-clone
spec:
  params:
    - name: repositorio
      type: string
      description: Repositório a ser clonado
      default: "https://github.com/raycon300/kakfka-poc"

  workspaces:
    - name: source
      description: Local onde o código será clonado

  steps:
    - name: clone
      image: alpine/git
      workingDir: $(workspaces.source.path)
      command:
        - /bin/sh
      args:
        - -c
        - git clone -v $(params.repositorio) ./source
```

```yaml 
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: file-list
spec:
  workspaces:
    - name: source
      description: Diretório

  steps:
    - name: list
      image: alpine
      workingDir: $(workspaces.source.path)
      command:
        - /bin/sh
      args:
        - -c
        - ls -l ./source
```

Agora vamos criar nossa Pipeline que vai executar as duas Tasks:

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: pipeline-com-workspace-empty-dir
spec:
  workspaces:
    - name: workspace-codebase          # (1) criando um workspace do type EmptyDir que vai ser usado pela pipeline
      description: Diretório compartilhado entre as tasks

  tasks:
    - name: clonar
      taskRef:
          name: git-clone
      workspaces:
        - name: source                  # (2) nome do workspace definido na task git-clone
          workspace: workspace-codebase # (3) nome do workspace que vai ser montado

    - name: listar
      taskRef:
          name: file-list
      workspaces:
        - name: source                   # (4) nome do workspace definido na task file-list
          workspace: workspace-codebase  # (5) nome do workspace que vai ser montado
      runAfter:
        - clonar
```

Vamos criar a Pipeline com o comando:

```bash
oc apply -f pipeline-com-workspace-empty-dir.yaml -n empresa-cicd
```

Vamos executar a Pipeline com o comando:

```bash
tkn pipeline start pipeline-com-workspace-empty-dir --showlog -w name=codebase,emptyDir=""
```

```bash
PipelineRun started: pipeline-com-workspace-empty-dir-run-m82pc
Waiting for logs to be available...
[clonar : clone] Cloning into './source'...
[clonar : clone] POST git-upload-pack (175 bytes)
[clonar : clone] POST git-upload-pack (217 bytes)

[listar : list] ls: ./source: No such file or directory # (1) o diretório ./source não existe pois o Emptydir é criado e destruído junto com a Task

failed to get logs for task listar : container step-list has failed  : [{"key":"StartedAt","value":"2023-07-28T20:48:23.076Z","type":3}]
```

Como o EmptyDir é criado e destruído junto com a Task, o diretório `./source` não existe na Task `listar` e a Task falha. Para resolver esse problema vamos usar um `PersistentVolumeClaim` como `VolumeSource` do Workspace.

## Criando uma Pipeline com um Workspace - PersistentVolumeClaim (PVC)

### Pré-requisitos
Antes de continuar, se quisermos utilizar um pvc ReadWriteMany, precisamos instalar o operador OpenShift Data Foundation no nosso cluster.
>Espere até que o ocs-storagecluster-storagesystem esteja com status `Ready` antes de continuar.


Vamos recriar a Pipeline anterior, mas agora vamos usar um `PersistentVolumeClaim` como `VolumeSource` do Workspace. Isso vai garantir que o conteúdo do Volume vai estar disponível para todas as Tasks da Pipeline.

```mermaid
POD -> persistentVolumeClaim (PVC) --> persistentVolume (PV)  
```

Vamos criar o `PersistentVolumeClaim` como descrito abaixo:
> Os arquivos de manifestos estão na pasta `k8s/pvc`

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pipelines-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
```

Agora vamos executar a pipeline informando o nome do PVC que foi criado:

```bash
tkn pipeline start pipeline-com-workspace-empty-dir --showlog -w name=codebase,claimNMame=pipelines-pvc
```

```bash
PipelineRun started: pipeline-com-workspace-pvc-run-m6xrf
Waiting for logs to be available...
[clonar : clone] Cloning into './source'...
[clonar : clone] POST git-upload-pack (175 bytes)
[clonar : clone] POST git-upload-pack (217 bytes)

[listar : list] total 36
[listar : list] -rw-rw-r--    1 root     10007000       613 Jul 31 16:59 README.md
[listar : list] drwxrwsr-x    2 root     10007000      4096 Jul 31 16:59 assets
[listar : list] drwxrwsr-x    2 root     10007000      4096 Jul 31 16:59 kafka-1
[listar : list] drwxrwsr-x    2 root     10007000      4096 Jul 31 16:59 kafka-2
[listar : list] -rw-rw-r--    1 root     10007000      1518 Jul 31 16:59 kafka-compose.yml
[listar : list] drwxrwsr-x    4 root     10007000      4096 Jul 31 16:59 kafka-consumer
[listar : list] drwxrwsr-x    4 root     10007000      4096 Jul 31 16:59 kafka-consumer-multi-cluster
[listar : list] drwxrwsr-x    4 root     10007000      4096 Jul 31 16:59 kafka-producer
[listar : list] drwxrwsr-x    4 root     10007000      4096 Jul 31 16:59 kafka-stream
```
Agora como não apagamos os dados do pvc quando a pipeline terminou, se executarmos novamente a pipeline o conteúdo do pvc vai estar disponível para as tasks o que no nosso caso vai gerar um erro.

```bash
tkn pipeline start pipeline-com-workspace-pvc --showlog -w name=codebase,claimName=pipelines-pvc
```

```bash
PipelineRun started: pipeline-com-workspace-pvc-run-cwq9t
Waiting for logs to be available...
[clonar : clone] fatal: destination path './source' already exists and is not an empty directory. # (1) o diretório ./source
```

## Criando um pipeline com um Workspace - VolumeClaimTemplate

Para essa tarefa podemos reutilizar a Pipeline anterior, mas vamos usar um `VolumeClaimTemplate` como `VolumeSource` do Workspace.

A forma mais simples de fazermos isto é criando o manifesto do PipelineRun como descrito abaixo.

```yaml
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: pipeline-com-workspace-pvc-run- # (1) o nome do PipelineRun vai ser gerado automaticamente usando o prefixo pipeline-com-workspace-pvc-run-
spec:
  pipelineRef:
    name: pipeline-com-workspace-pvc # (2) nome da pipeline que vai ser executada
  timeouts:
    pipeline: 20m0s # (3) tempo máximo de execução da pipeline
  workspaces:
    - name: codebase # (4) nome do workspace que vai ser montado (o mesmo nome definido na pipeline)
      volumeClaimTemplate: # (5) criando um volumeClaimTemplate que vai ser usado como volumeSource do workspace
        spec:
          accessModes:
            - ReadWriteOnce # (6) o volume vai ser montado como ReadWriteOnce - O tipo de acesso ao volume (ReadWriteOnce, ReadOnlyMany, ReadWriteMany) pode influenciar a forma de usar o volume em tasks paralelas
          resources:
            requests:
              storage: 1Gi
```

Vamo utlizar o comando `oc create` para criar o PipelineRun:

```bash
oc create -f pr-pipeline-com-volume-claim-template-run.yaml -n empresa-cicd
```
Para acompanhar a execução da PipelineRun podemos usar o comando:

```bash
# A opção -L vai mostrar os logs da execução da última pipeline run executada/executando
tkn pr logs -L -f -n empresa-cicd
```

Se continuarmos repetindo a execução dos dois comandos acima, vamos ver que o nome do PipelineRun vai ser incrementado automaticamente, a Pipeline vai ser executada o conteúdo do Volume vai estar disponível para as Tasks, mas uma execução não vai afetar a outra e tão logo a PipelineRun seja apagada o VolumeTemplateClaim também vai ser excluído.

Podemos constatar isso executando o comando:

```bash
oc get pvc -n empresa-cicd
```
```bash
NAME             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pipelines-pvc    Bound    pvc-1b3e000d-a338-45fe-a1aa-6fc56b411ab9   1Gi        RWO            gp3-csi        94m
pvc-7252a55b19   Bound    pvc-da7514af-6214-428a-aca6-edd911806560   1Gi        RWO            gp3-csi        93s # (1) o volume foi criado junto com a PipelineRun e vai ser excluído quando a PipelineRun for excluída
```

Agora vamos apagar todos os nossos PipelineRuns:

```bash
tkn pr delete -n empresa-cicd --all
```

```bash
Are you sure you want to delete all PipelineRuns in namespace "empresa-cicd" (y/n): y

All PipelineRuns(Completed) deleted in namespace "empresa-cicd"
```

Se executarmos o comando `oc get pvc -n empresa-cicd` vamos ver que o PVC `pipelines-pvc` ainda existe, pois ele não foi criado pelo PipelineRun e não vai ser excluído quando a PipelineRun for excluída, todavia todos os outros que foram criados utilizando VolumeTemplateClaim vão ser deletados.

```bash
oc get pvc -n empresa-cicd
```

```bash
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pipelines-pvc   Bound    pvc-1b3e000d-a338-45fe-a1aa-6fc56b411ab9   1Gi        RWO            gp3-csi        97m
```


# Deletar Pipelines e Pipelines Run


Para deltar todas as Pipelines Run e Pipelines do namespace `empresa-cicd` podemos usar os comandos:
```bash
tkn pipeline delete --all -n empresa-cicd
```

```bash
tkn pr delete --all -n empresa-cicd
```

Para deletar todas as Pipelines Run e Pipelines do namespace `empresa-cicd` exceto as 2 últimas podemos usar os comandos:

```bash
tkn pipeline delete --keep 2 -n empresa-cicd
```

```bash
tkn pr delete --keep 2 -n empresa-cicd
```


# Autenticação em Repositórios Git privados

Para usar recursos privados do git precisamos criar um `Secret` que vai ser usado para autenticar no git.

> Precisamos criar um [Classic Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) no git e usar o token como senha no `Secret`. 

Por questões de segurança e governaça nós vamos criar o `Secret` utilzando o `External Secret` conectado ao Vault, como descrito abaixo:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: git-basic-auth-ext      # (1) nome do ExternalSecret
spec:
  secretStoreRef:
    name: vault-backend         # (2) nome do ClusterSecretStore criado anteriormente
    kind: ClusterSecretStore    # (3) ClusterSecretStore ou SecretStore (nesse caso estamos usando clustersecretstore)
  refreshInterval: "1h"         # (4) intervalo de tempo para sincronizar a secret do vault com a secret do openshift ( valores válidos: 1h, 1m, 1s, 1ms, 1us, 1ns)
  target:
    name: git-basic-auth        # (5) nome da secret que será criada no openshift
    template:
      type: kubernetes.io/basic-auth
      engineVersion: v2
      metadata:
        annotations:
          tekton.dev/git-0: https://github.com
      data:
        username: "{{ .user }}"     # (6) valor da propriedade password
        password: "{{ .password }}" # (7) valor da propriedade user

  data:
    - secretKey: user               # (8) nome da propriedade que será criada na secret do openshift (nesse caso o nome da propriedade que vamos usar no template)
      remoteRef:
        key: projeto-poc/git-basic-auth # (10) path da secret kv no vault
        property: user                  # (11) nome da propriedade do secret kv no vault

    - secretKey: password
      remoteRef:
        key: projeto-poc/git-basic-auth
        property: password
```

Agora vamos criar o `Secret` que vai ser usado para autenticar no git:

```bash
oc apply -f secret-git-basic-auth.yaml -n empresa-cicd
```

Vamos validar que o External Secret e o Secret foram criados:

```bash
oc get externalsecret -n empresa-cicd
```

```bash
NAME                 STORE           REFRESH INTERVAL   STATUS         READY
git-basic-auth-ext   vault-backend   1h                 SecretSynced   True
```

```bash
oc get secret -n empresa-cicd
```

```bash
NAME                                             TYPE                                  DATA   AGE
git-basic-auth                                   Opaque                                2      2m42s
```

Precisamos associar essa secret ao ServiceAccount `pipeline` para que a pipeline possa usar o secret para autenticar no git:

>Se não fizermos isso a pipeline vai falhar ao tentar clonar o repositório privado. <br>
Se houver uma pipeline por namespace, teremos que executar essas etapas _(criar a secret e fazero patch)_ para cada novo namespace.<br>
Uma alternativa seria ao invés de associar a secret a um ServiceAccount, montar a secret como uma variável de ambiente _(veja o arquivo task-ler-secret.yaml)_.<br>
Como a secret está armazenada no Vault não seria um problema utilizar o git com a External Secret e usarmos o ArgoCD para criar o recurso no namespace.

```bash
oc patch serviceaccount pipeline -p '{"secrets": [{"name": "git-basic-auth"}]}' -n empresa-cicd
```

Vamos validar que a secret foi associada ao ServiceAccount:

```bash
oc get sa/pipeline -o yaml -n empresa-cicd
```

```yaml
apiVersion: v1
imagePullSecrets:
  - name: pipeline-dockercfg-f9bln
kind: ServiceAccount
metadata:
  creationTimestamp: "2023-07-27T15:58:46Z"
  name: pipeline
  namespace: empresa-cicd
  ownerReferences:
    - apiVersion: operator.tekton.dev/v1alpha1
      blockOwnerDeletion: true
      controller: true
      kind: TektonConfig
      name: config
      uid: 800d5bdf-79d3-4bf4-b4bd-5760cc90efdd
  resourceVersion: "1976291"
  uid: 17a24c1c-ac8b-45f6-9c14-e13e636535b8
secrets:
  - name: git-basic-auth  # (1) nome da secret que foi associada ao ServiceAccount
  - name: pipeline-dockercfg-f9bln
```

Agora vamos criar uma Pipeline que vai clonar um repositório privado do git, para isso vamos utilizar um PipelineRun:

```bash
oc create -f pr-git-private-repo.yaml -n empresa-cicd
```

Vamos acompanhar a execução da PipelineRun:

```bash
tkn pr logs -L -f -n empresa-cicd
```

```bash
[clonar : clone] Cloning into './source'...
[clonar : clone] POST git-upload-pack (175 bytes)
[clonar : clone] POST git-upload-pack (217 bytes)

[listar : list] total 4
[listar : list] -rw-rw-r--    1 root     10007000      1598 Aug  2 00:23 README.md
```