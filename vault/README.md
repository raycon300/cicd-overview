# Instalação do Vault e External Secret no Openshift

Esse documento descreve os passos necessários para instalar o Vault e o External Secret no Openshift.

## Vault

### Criar o namespace
```bash
oc new-project vault
```

### Adicionar o repositório Helm
```bash
helm repo add openshift-helm-charts https://charts.openshift.io/
```

```bash
helm repo update
```

### Instalar o Vault
```bash
cd vault
```

```bash
helm install vault openshift-helm-charts/hashicorp-vault \
-f ./vault-values.yaml -n vault
```

### Validar que os pods estão em running
```bash
watch -n2 oc get pods -n vault
```

```bash
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 0/1     Running   0          2m38s
vault-1                                 0/1     Running   0          2m38s
vault-2                                 0/1     Running   0          2m38s
vault-agent-injector-76577ddc8f-2xgwx   1/1     Running   0          2m38s
```

### Iniciar o Vault

Após os pods estarem em running, vamos iniciar o Vault.

```bash
oc exec -it -n vault vault-0 -- vault operator init
```

```bash
Unseal Key 1: uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB
Unseal Key 2: he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI
Unseal Key 3: 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m
Unseal Key 4: QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli
Unseal Key 5: Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w

Initial Root Token: hvs.g1F5J6uqubiPJk2rsIdzx3Ko            # Root Token to be used in the login step


Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```
É importante salvar o `Initial Root Token` e as `Unseal Keys` geradas, pois elas serão utilizadas para fazer o login no Vault e para realizar o unseal do Vault.

### Unseal do Vault no pod vault-0
```bash
oc exec -it -n vault vault-0 -- vault operator unseal uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB # Unseal Key 1
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       1f146ff2-1496-a03a-820b-8295cf3a430d
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-0 -- vault operator unseal he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI # Unseal Key 2
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       1f146ff2-1496-a03a-820b-8295cf3a430d
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-0 -- vault operator unseal 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m # Unseal Key 3

Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 active
Active Since            2023-07-26T18:06:45.098309611Z
Raft Committed Index    36
Raft Applied Index      36
```

```bash
oc exec -it -n vault vault-0 -- vault operator unseal QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli # Unseal Key 4

Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 active
Active Since            2023-07-26T18:06:45.098309611Z
Raft Committed Index    38
Raft Applied Index      38
```

```bash
oc exec -it -n vault vault-0 -- vault operator unseal Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w # Unseal Key 5

Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 active
Active Since            2023-07-26T18:06:45.098309611Z
Raft Committed Index    38
Raft Applied Index      38
```

### Conectar vault-1 no vault-0

```bash
oc exec -it -n vault vault-1 -- vault operator raft join \
http://vault-active:8200

http://vault-active:8200
Key       Value
---       -----
Joined    true
```

### Unseal do Vault no pod vault-1

```bash
oc exec -it -n vault vault-1 -- vault operator unseal uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB # Unseal Key 1
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       6cb35f4c-e9c8-fce6-1937-1f52d61c5a0b
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-1 -- vault operator unseal he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI # Unseal Key 2
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       6cb35f4c-e9c8-fce6-1937-1f52d61c5a0b
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-1 -- vault operator unseal 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m # Unseal Key 3
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    0/3
Unseal Nonce       n/a
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-1 -- vault operator unseal QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli # Unseal Key 4
```

```bash
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 standby
Active Node Address     http://10.130.0.19:8200
Raft Committed Index    40
Raft Applied Index      40
```

```bash
oc exec -it -n vault vault-1 -- vault operator unseal Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w # Unseal Key 5
```

```bash
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 standby
Active Node Address     http://10.130.0.19:8200
Raft Committed Index    40
Raft Applied Index      40
```

### Conectar vault-2 no vault-0

```bash
oc exec -it -n vault vault-2 -- vault operator raft join \
http://vault-active:8200

http://vault-active:8200
Key       Value
---       -----
Joined    true
```

### Unseal do Vault no pod vault-2

```bash
oc exec -it -n vault vault-2 -- vault operator unseal uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB # Unseal Key 1
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    1/3
Unseal Nonce       8ac0e129-71c5-9856-8265-9b87b417cc91
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-2 -- vault operator unseal he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI # Unseal Key 2
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    2/3
Unseal Nonce       8ac0e129-71c5-9856-8265-9b87b417cc91
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-2 -- vault operator unseal 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m # Unseal Key 3
```

```bash
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       5
Threshold          3
Unseal Progress    0/3
Unseal Nonce       n/a
Version            1.11.3
Build Date         2022-08-26T10:27:10Z
Storage Type       raft
HA Enabled         true
```

```bash
oc exec -it -n vault vault-2 -- vault operator unseal QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli # Unseal Key 4

Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 standby
Active Node Address     http://10.130.0.19:8200
Raft Committed Index    42
Raft Applied Index      42
```

```bash
oc exec -it -n vault vault-0 -- vault operator unseal Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w # Unseal Key 5
```

```bash
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 active
Active Since            2023-07-26T18:06:45.098309611Z
Raft Committed Index    42
Raft Applied Index      42
```
### Validar que os pods estão running

```bash
oc get pods -n vault       
```

```bash
NAME                                    READY   STATUS    RESTARTS   AGE
vault-0                                 1/1     Running   0          164m
vault-1                                 1/1     Running   0          164m
vault-2                                 1/1     Running   0          164m
vault-agent-injector-76577ddc8f-2xgwx   1/1     Running   0          164m

```

### Login no Vault

```bash
oc get route -n vault
```

Use o `Initial Root Token` gerado no comando `vault operator init` para fazer o login no Vault.


## External Secret

### Criar o namespace

```bash
oc new-project external-secrets
```

### Adicionar o repositório Helm

```bash
helm repo add external-secrets https://charts.external-secrets.io
```

```bash
helm repo update
```

### Instalar o External Secret

```bash
helm install external-secrets \
external-secrets/external-secrets -n external-secrets
```

### Dar permissão anyuid para o service account do external-secrets

```bash
oc adm policy add-scc-to-user privileged system:serviceaccount:external-secrets:external-secrets # oc adm policy add-scc-to-user <scc_name> <user_name>
``` 

```bash
oc adm policy add-scc-to-user privileged system:serviceaccount:external-secrets:external-secrets-cert-controller # oc adm policy add-scc-to-user <scc_name> <user_name>
```

```bash
oc adm policy add-scc-to-user privileged system:serviceaccount:external-secrets:external-secrets-webhook  # oc adm policy add-scc-to-user <scc_name> <user_name>
```

Vamos validar que os pods foram criados

```bash
oc get all -n external-secrets
```

```bash

NAME                                                    READY   STATUS    RESTARTS   AGE
pod/external-secrets-6fd48dd75b-gsjbq                   1/1     Running   0          3m7s
pod/external-secrets-cert-controller-86c6b8b74f-xknrz   1/1     Running   0          3m7s
pod/external-secrets-webhook-5475f78dd6-ksd8q           1/1     Running   0          3m7s

NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
service/external-secrets-webhook   ClusterIP   172.30.229.147   <none>        443/TCP   3h34m

NAME                                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/external-secrets                   1/1     1            1           3h34m
deployment.apps/external-secrets-cert-controller   1/1     1            1           3h34m
deployment.apps/external-secrets-webhook           1/1     1            1           3h34m

NAME                                                          DESIRED   CURRENT   READY   AGE
replicaset.apps/external-secrets-69ccdc65c9                   0         0         0       3h34m
replicaset.apps/external-secrets-6fd48dd75b                   1         1         1       16m
replicaset.apps/external-secrets-cert-controller-86c6b8b74f   1         1         1       3h34m
replicaset.apps/external-secrets-webhook-5475f78dd6           1         1         1       3h34m
```

### Criar a secret com as credenciais do Vault

Podemos criar utilizando o arquivo secret.yaml 
```bash
oc create -f secret.yaml -n vault 
```
ou executando o comando abaixo:

```bash
cat <<EOF | oc create -n vault -f -
apiVersion: v1
kind: Secret
metadata:
  name: vault-token
  namespace: vault
stringData:
  token: hvs.g1F5J6uqubiPJk2rsIdzx3Ko
  unseal_key_1: uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB
  unseal_key_2: he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI
  unseal_key_3: 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m
  unseal_key_4: QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli
  unseal_key_5: Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w
EOF
```

### Criar ClusterSecretStore com as configurações do Vault
Podemos criar utilizando o arquivo clustersecretstore.yaml 

```bash
oc create -f clustersecretstore.yaml -n external-secrets
```
ou executando o comando abaixo:

```bash
cat <<EOF | oc create -f -
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-backend
spec:
  provider:
    vault:
      server: "http://vault-active.vault.svc.cluster.local:8200"
      version: "v2"
      auth:
        tokenSecretRef:
          name: "vault-token"
          key: "token"
          namespace: vault
EOF
```
### Validando que o ClusterSecretStore foi criado

```bash
oc get clustersecretstore
```

```bash
NAME            AGE   STATUS   CAPABILITIES   READY
vault-backend   38m   Valid    ReadWrite      True
```
> Caso o campo `READY` não esteja como `True` pode ser o caso do cluster ter reiniciado e os pods do Voult estarem unsealed _(veja a session de Dicas para saber como realizar o unseal de um vault já configurado)_.

### Criar um ExternalSecret

Agora vamos criar uma secret no Vault para ser consumida pelo External Secret.
Primeiro vamos criar um projeto de exemplo:

```bash
oc new-project projeto-poc
```

Agora vamos criar a secret:

```bash
cat <<EOF | oc apply -n projeto-poc -n projeto-poc -f -
 apiVersion: external-secrets.io/v1beta1
 kind: ExternalSecret
 metadata:
   name: vault-secret
 spec:
   secretStoreRef:
     name: vault-backend        # nome do ClusterSecretStore criado anteriormente
     kind: ClusterSecretStore   # ClusterSecretStore ou SecretStore (nesse caso estamos usando clustersecretstore)
   refreshInterval: "1h"      # intervalo de tempo para sincronizar a secret do vault com a secret do openshift ( valores válidos: 1h, 1m, 1s, 1ms, 1us, 1ns)
   target:
     name: vault-secret-example # nome da secret que será criada no openshift
   data:
   - secretKey: password        # nome da propriedade que será criada na secret do openshift
     remoteRef:
       key: projeto-poc/exemplo # path da secret kv no vault
       property: password       # nome da propriedade que será criada na secret do openshift
EOF
```

Ou podemos criar utilizando o arquivo externalsecret.yaml 

```bash
oc create -f externalsecret.yaml -n projeto-poc
```

### Validando que a ExternalSecret e a  Secret correspondente foram criadas

```bash
oc get externalsecret -n projeto-poc
```

```bash
NAME           STORE           REFRESH INTERVAL   STATUS         READY
vault-secret   vault-backend   1h                 SecretSynced   True
```

```bash
oc get secret -n projeto-poc
```

```bash
NAME                       TYPE                                  DATA   AGE
builder-dockercfg-2v8fl    kubernetes.io/dockercfg               1      4m51s
builder-token-l9lvl        kubernetes.io/service-account-token   4      4m51s
default-dockercfg-dmc8l    kubernetes.io/dockercfg               1      4m51s
default-token-9mfr5        kubernetes.io/service-account-token   4      4m51s
deployer-dockercfg-7mbsr   kubernetes.io/dockercfg               1      4m51s
deployer-token-pnbst       kubernetes.io/service-account-token   4      4m51s
vault-secret-example       Opaque                                1      15s      # Secret criada pelo External Secret
```

Caso a `ExternalSecret` seja deletada, a `Secret` correspondente também será apagada. _(Os valores no Vault não serão apagados)_

Caso a `Secret` seja deletada, a `ExternalSecret` não será apagada e a `Secret` será recriada automáticamente.

# Vault Client

Para configurar o Vault Client, execute os comandos abaixo:

### Instalar o Vault Client OSx

```bash
brew tap hashicorp/tap
```

```bash
brew install hashicorp/tap/vault
```

### Autenticando no Vault via CLI

```bash
export VAULT_ADDR=https://$(oc get route vault -n vault --output jsonpath={.spec.host})
```

```bash
export VAULT_TOKEN=$(oc get secret vault-token -n vault -o jsonpath={.data.token} | base64 -d )
```

```bash
vault status
```

```bash
Key                     Value
---                     -----
Seal Type               shamir
Initialized             true
Sealed                  false
Total Shares            5
Threshold               3
Version                 1.11.3
Build Date              2022-08-26T10:27:10Z
Storage Type            raft
Cluster Name            vault-cluster-831f4641
Cluster ID              4179d5ae-63d6-d8bf-8a65-deea3a10c8c8
HA Enabled              true
HA Cluster              https://vault-0.vault-internal:8201
HA Mode                 active
Active Since            2023-07-26T18:06:45.098309611Z
Raft Committed Index    42
Raft Applied Index      42
```

Podemos obter informações sobre a secret:

```bash
vault kv get projeto-poc/exemplo
```

```bash
====== Secret Path ======
projeto-poc/data/exemplo

======= Metadata =======
Key                Value
---                -----
created_time       2023-07-27T05:03:57.172611551Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1

====== Data ======
Key         Value
---         -----
password    abc123
```

Caso seja necessário podemos obter o valor da propriedade `password` configurada no path `projeto-poc/exemplo`:

```bash 
vault kv get -field=password projeto-poc/exemplo
```

```bash
abc123
```


# Dicas

Quando o cluster stopar, o Vault vai ficar em `sealed`. Para realizar o `desseal`, execute os comandos abaixo:
>Quando o cluster estiver sealed, os pods do vault vão ficar em 0/1 e a console web vai ficar indisponível.

```bash
oc exec -it -n vault vault-0 -- vault operator unseal uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB # Unseal Key 1
oc exec -it -n vault vault-0 -- vault operator unseal he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI # Unseal Key 2
oc exec -it -n vault vault-0 -- vault operator unseal 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m # Unseal Key 3
oc exec -it -n vault vault-0 -- vault operator unseal QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli # Unseal Key 4
oc exec -it -n vault vault-0 -- vault operator unseal Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w # Unseal Key 5

oc exec -it -n vault vault-1 -- vault operator unseal uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB # Unseal Key 1
oc exec -it -n vault vault-1 -- vault operator unseal he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI # Unseal Key 2
oc exec -it -n vault vault-1 -- vault operator unseal 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m # Unseal Key 3
oc exec -it -n vault vault-1 -- vault operator unseal QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli # Unseal Key 4
oc exec -it -n vault vault-1 -- vault operator unseal Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w # Unseal Key 5

oc exec -it -n vault vault-2 -- vault operator unseal uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB # Unseal Key 1
oc exec -it -n vault vault-2 -- vault operator unseal he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI # Unseal Key 2
oc exec -it -n vault vault-2 -- vault operator unseal 0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m # Unseal Key 3
oc exec -it -n vault vault-2 -- vault operator unseal QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli # Unseal Key 4
oc exec -it -n vault vault-2 -- vault operator unseal Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w # Unseal Key 5
```

```bash
for i in {0..2}; do
    for s in {"uMuIO5YLlwM3k8lrl8CM9FrcKsjcaXUUjpTpEwC+6bYB","he3iSG2TMWm5sTAKRoACW92UB0srnOrOtLKicdjIuscI","0FjjZk/emY5TuVsxZzFro1BN4MS2wgHNSPMgvzbVsg1m","QLF26s/P59GyyJR5kGfBMKgtlmm12DEVVeq2I0vK7jli","Zchy6BAGMFTH1hILJtgnxoQXiSsx3dt4+IQ0BqtJEP1w"}; do
        oc exec -it -n vault vault-$i -- vault operator unseal $s;
    done
done
```
>Podemos utilizar o Helm chart [refresh-connection-es-to-vault](https://github.com/dsferreira54/refresh-connection-es-to-vault) para automatizar o processo de unseal.<br>

