# Operating rules

Working agreements for this lab. Anyone picking up the repository, including a
future me, should be able to follow these without further context.

## Guardrails

The AWS account is live and the working identity holds AdministratorAccess.

- Every AWS command carries `--profile lab`. There is no default profile by design,
  so a command missing it fails loudly instead of silently falling back to something
  privileged.
- Expired session: `aws sso login --profile lab`. Never `aws login`, which can attach
  a root session.
- The root user is not used for operational work.
- Creating, modifying or deleting an AWS resource requires stating the hourly cost
  first. Read-only calls need no ceremony.
- The database is never publicly accessible. Nothing gets `0.0.0.0/0` except ALB
  ingress on 443.
- Terraform state is sensitive: encrypted, locked, access-restricted, never committed.
- Every session ends with `./scripts/capture-evidence.sh <milestone>` and a report of
  the billable inventory. Anything left running has a recorded reason.

### Cost drivers, us-east-1 on-demand, approximate

| Resource | While running |
|---|---|
| NAT Gateway | ~USD 0.045/h plus data |
| Application Load Balancer | ~USD 0.023/h plus usage |
| RDS db.t4g.micro | ~USD 0.016/h single-AZ; storage bills when stopped |
| ECS Fargate, two small tasks | ~USD 0.025/h combined |

VPCs, subnets, route tables, internet gateways and security groups are free. A short
working session costs cents; a month left running costs two orders of magnitude more.
That gap is the entire argument for tearing down on exit.

### Required tags on every billable resource

`project=aws-reliability-lab` · `env=lab` · `owner=@fantasmagorikus` ·
`managed-by=cloudformation|terraform|console`

`managed-by=console` marks anything created by hand, which no stack teardown will
remove. It is the tag that finds forgotten spend.

## Security posture

Security controls are applied by default, and each one is documented with the concept
behind it. A control whose threat model cannot be explained is a control that cannot
be defended.

- Least privilege: the narrowest permission that does the job, demonstrated by testing
  one allowed action and one denied action.
- Defense in depth: no single control is load-bearing. Network boundary, security
  group, IAM policy and application check each catch what the others miss.
- Fail closed: when a control is missing or misconfigured, the system denies rather
  than allows. Defaults that do the opposite are called out.
- Encryption in transit and at rest by default, with the key type and its cost stated.
  Customer managed KMS keys bill monthly; AWS managed keys do not.
- Secrets never live in code, environment files, shell history or version control.
- Knowingly accepted risks are recorded with a deadline rather than left to fade.

## Evidence discipline

An audit of this repository found overclaims in an earlier revision. These rules exist
because of that.

- An inference is never written as if it were verified. A claim not backed by captured
  command output is either labelled unverified or left out.
- A resource existing is not proof it is configured correctly. Read the authoritative
  field, not an adjacent signal.
- Validation runs both directions: the allowed path must work and the denied path must
  fail. A milestone is not done until its failure case has been tested.
- No metric enters any document without a recorded measurement.
- Prior summaries and automated reports are hypotheses, verified against actual state.

## Target architecture

Design intent, not yet built.

- One VPC, `10.20.0.0/16`, two Availability Zones, six subnets in three tiers: public
  (ALB and NAT), private application (ECS Fargate), isolated database (RDS). The
  isolated tier has no route to the internet.
- Traffic flows one direction only:
  `internet -443-> ALB -app port-> ECS -5432-> RDS`
- Separate ECS task execution role and application task role. Neither gets
  `AdministratorAccess`.
- Secrets Manager for database credentials. Never in environment files or code.
- CloudFormation first, working, then ported to Terraform modules. The two never
  manage the same live resource simultaneously unless a migration is deliberate.
- SAM only for a small optional serverless automation, never for ECS or RDS.

Kubernetes, multiple microservices, multi-region failover and service mesh are out of
scope for the first release. One service, proven end to end, comes first.

## Account facts that affect commands

- A default VPC exists in us-east-1 (1 VPC, 6 subnets, free). Once the lab VPC is
  created, any query without a filter returns both. Filter explicitly with
  `--filters Name=isDefault,Values=false` and never assume the first result is the lab
  VPC. Whether to delete the default VPC is an open decision for M1.
- `DescribeNatGateways` has been returning `InternalError` in us-east-1, persistently,
  while the same call succeeds in us-east-2. When it fails, the failure is recorded as
  such rather than reported as zero, and spend is cross-checked through Cost Explorer.

## Conventions

- Commits follow Conventional Commits: imperative subject under 50 characters, blank
  line, body explaining why.
- Repository content is in English. Prose documents carry a PT-BR version below the
  English one in the same file, written without accents.
- ADRs are immutable. From M1 onward they are written as `proposed` before the decision
  is made, reviewed, then flipped to `accepted`. A changed decision gets a new ADR that
  supersedes the old one.
- Bash uses `set -euo pipefail`, with expected-failure commands marked `{ ...; } || true`
  so strict mode does not abort the run.
- The repository is public and pushed. History rewriting is no longer available;
  corrections are new commits.

## Open items

- Second-factor coverage for the root and administrative identities is tracked
  privately, outside this repository. The measurement gap is the part worth publishing:
  `aws iam get-account-summary --profile lab --query 'SummaryMap.AccountMFAEnabled'`
  covers the root user only. The administrative identity is an Identity Center directory
  user and no CLI check for its second factor has been found, so it remains a manual
  console verification. All checks passing is not the same as the account being
  protected.
- Two claims still rest on inference and need the authoritative check, recorded at the
  end of `PLAN.md`: Identity Center Single-Region, and organization instance versus
  account instance.

---

# Regras operacionais (PT-BR)

Acordos de trabalho deste laboratorio. Qualquer pessoa que pegue o repositorio,
inclusive eu no futuro, deve conseguir segui-los sem contexto adicional.

## Guardrails

A conta AWS esta ativa e a identidade de trabalho possui AdministratorAccess.

- Todo comando AWS leva `--profile lab`. Nao existe perfil default por decisao de
  projeto, entao um comando sem ele falha alto em vez de cair silenciosamente em algo
  privilegiado.
- Sessao expirada: `aws sso login --profile lab`. Nunca `aws login`, que pode anexar
  uma sessao de root.
- O usuario root nao e usado para trabalho operacional.
- Criar, modificar ou deletar recurso AWS exige declarar o custo por hora antes.
  Chamadas somente leitura nao precisam de cerimonia.
- O banco de dados nunca fica publicamente acessivel. Nada recebe `0.0.0.0/0` exceto
  a entrada do ALB na porta 443.
- O state do Terraform e material sensivel: criptografado, com lock, acesso restrito,
  nunca commitado.
- Toda sessao termina com `./scripts/capture-evidence.sh <milestone>` e um relato do
  inventario cobravel. O que ficar ligado tem motivo registrado.

### Geradores de custo, us-east-1 sob demanda, aproximado

| Recurso | Enquanto ligado |
|---|---|
| NAT Gateway | ~USD 0,045/h mais trafego |
| Application Load Balancer | ~USD 0,023/h mais uso |
| RDS db.t4g.micro | ~USD 0,016/h single-AZ; armazenamento cobra com a instancia parada |
| ECS Fargate, duas tasks pequenas | ~USD 0,025/h no total |

VPCs, sub-redes, tabelas de rota, internet gateways e security groups sao gratuitos.
Uma sessao curta custa centavos; um mes esquecido ligado custa duas ordens de grandeza
a mais. Essa diferenca e todo o argumento para destruir ao sair.

### Tags obrigatorias em todo recurso cobravel

`project=aws-reliability-lab` · `env=lab` · `owner=@fantasmagorikus` ·
`managed-by=cloudformation|terraform|console`

`managed-by=console` marca o que foi criado a mao, que nenhum teardown de stack
remove. E a tag que encontra gasto esquecido.

## Postura de seguranca

Controles de seguranca sao aplicados por padrao, e cada um e documentado com o conceito
por tras. Um controle cujo modelo de ameaca nao pode ser explicado e um controle que
nao pode ser defendido.

- Menor privilegio: a permissao mais estreita que resolve a tarefa, demonstrada com um
  teste de acao permitida e outro de acao negada.
- Defesa em profundidade: nenhum controle sozinho sustenta o sistema. Fronteira de
  rede, security group, politica IAM e verificacao na aplicacao pegam coisas diferentes.
- Falhar fechado: quando um controle falta ou esta mal configurado, o sistema nega em
  vez de permitir. Padroes que fazem o contrario sao apontados.
- Criptografia em transito e em repouso por padrao, com o tipo de chave e seu custo
  declarados. Chaves KMS customer managed cobram mensalmente; as gerenciadas pela AWS
  nao.
- Segredos nunca ficam em codigo, arquivos de ambiente, historico de shell ou controle
  de versao.
- Riscos aceitos conscientemente sao registrados com prazo em vez de sumirem.

## Disciplina de evidencia

Uma auditoria deste repositorio encontrou afirmacoes exageradas em uma revisao
anterior. Estas regras existem por causa disso.

- Inferencia nunca e escrita como se fosse verificada. Afirmacao sem saida de comando
  capturada e rotulada como nao verificada ou fica de fora.
- Um recurso existir nao prova que esta configurado corretamente. Ler o campo
  autoritativo, nao um sinal adjacente.
- Validacao roda nos dois sentidos: o caminho permitido deve funcionar e o negado deve
  falhar. Um milestone nao esta concluido ate seu caso de falha ser testado.
- Nenhuma metrica entra em documento sem medicao registrada.
- Resumos anteriores e relatorios automatizados sao hipoteses, verificadas contra o
  estado real.

## Arquitetura alvo

Intencao de projeto, ainda nao construida.

- Uma VPC, `10.20.0.0/16`, duas Availability Zones, seis sub-redes em tres camadas:
  publica (ALB e NAT), privada de aplicacao (ECS Fargate), isolada de banco (RDS). A
  camada isolada nao tem rota para a internet.
- O trafego flui em uma direcao apenas:
  `internet -443-> ALB -porta da app-> ECS -5432-> RDS`
- Task execution role e task role da aplicacao separadas. Nenhuma recebe
  `AdministratorAccess`.
- Secrets Manager para credenciais do banco. Nunca em arquivo de ambiente ou codigo.
- CloudFormation primeiro, funcionando, depois portado para modulos Terraform. Os dois
  nunca gerenciam o mesmo recurso ao mesmo tempo, exceto em migracao deliberada.
- SAM apenas para uma pequena automacao serverless opcional, nunca para ECS ou RDS.

Kubernetes, multiplos microsservicos, failover multi-regiao e service mesh estao fora
de escopo do primeiro release. Um servico, provado ponta a ponta, vem primeiro.

## Fatos da conta que afetam comandos

- Existe uma VPC padrao em us-east-1 (1 VPC, 6 sub-redes, gratuita). Depois que a VPC
  do laboratorio for criada, qualquer consulta sem filtro retorna as duas. Filtrar
  explicitamente com `--filters Name=isDefault,Values=false` e nunca supor que o
  primeiro resultado e a VPC do laboratorio. Deletar ou nao a VPC padrao e decisao
  aberta para o M1.
- `DescribeNatGateways` vem retornando `InternalError` em us-east-1 de forma
  persistente, enquanto a mesma chamada funciona em us-east-2. Quando falha, a falha e
  registrada como tal em vez de reportada como zero, e o gasto e conferido pelo Cost
  Explorer.

## Convencoes

- Commits seguem Conventional Commits: assunto no imperativo com menos de 50
  caracteres, linha em branco, corpo explicando o porque.
- Conteudo do repositorio em ingles. Documentos em prosa carregam versao PT-BR abaixo
  da inglesa no mesmo arquivo, escrita sem acentos.
- ADRs sao imutaveis. A partir do M1 sao escritos como `proposed` antes da decisao,
  revisados, e entao mudados para `accepted`. Decisao alterada gera um ADR novo que
  supera o antigo.
- Bash usa `set -euo pipefail`, com comandos de falha esperada marcados como
  `{ ...; } || true` para o modo estrito nao abortar a execucao.
- O repositorio e publico e ja foi enviado. Reescrita de historico nao esta mais
  disponivel; correcoes sao commits novos.

## Itens em aberto

- A cobertura de segundo fator das identidades root e administrativa e acompanhada de
  forma privada, fora deste repositorio. A lacuna de medicao e a parte que vale
  publicar: o comando
  `aws iam get-account-summary --profile lab --query 'SummaryMap.AccountMFAEnabled'`
  cobre apenas o root. A identidade administrativa e usuario do diretorio do Identity
  Center e nenhuma verificacao por CLI do seu segundo fator foi encontrada, entao
  permanece checagem manual no console. Todos os checks passando nao e o mesmo que a
  conta estar protegida.
- Duas afirmacoes ainda repousam em inferencia e precisam da verificacao autoritativa,
  registrada no fim do `PLAN.md`: Single-Region do Identity Center, e instancia de
  organizacao versus instancia de conta.
