# Cost controls

## Budget

- A fixed monthly cost budget is configured in AWS Budgets.
- Alerts fire at 50% actual, 80% actual, and 100% forecasted.
- AWS Budgets is notification-only. It does not stop resources. Destroy
  discipline is the primary control; the alert is the second line of defence.

## Tagging convention

Every billable resource carries these four tags:

| Key | Value | Purpose |
|---|---|---|
| project | aws-reliability-lab | filter this lab's spend in Cost Explorer |
| env | lab | separate from any future prod-like environment |
| owner | @phantasmagorie | accountability |
| managed-by | cloudformation \| terraform \| console | find anything created by hand |

The managed-by tag is the important one: any resource tagged console was created
outside infrastructure as code and will not be removed by a stack teardown.

## Main cost drivers (us-east-1, on-demand, approximate list prices)

| Resource | While running | Note |
|---|---|---|
| NAT Gateway | ~USD 0.045/h + data | bills every hour it exists |
| Application Load Balancer | ~USD 0.023/h + usage | same |
| RDS db.t4g.micro | ~USD 0.016/h single-AZ | storage bills even when stopped |
| ECS Fargate, 2 small tasks | ~USD 0.025/h combined | per running task |

Full stack running: roughly USD 0.12-0.18 per hour, so a short working session
costs cents while an environment left up for a month costs two orders of
magnitude more. That gap is the entire argument for the destroy policy below.

Figures to be verified against the AWS Pricing Calculator before Phase 1.

## Destroy policy

- No session ends without a destroy decision, recorded in PROJECT_STATE.md.
- Verify after teardown: no NAT Gateway, no load balancer, no RDS instance,
  no Elastic IP left allocated.
- Anything intentionally kept running is listed in PROJECT_STATE.md with a reason.

---

# Controles de custo (PT-BR)

## Orcamento

- Um orcamento mensal fixo esta configurado no AWS Budgets.
- Alertas disparam em 50% realizado, 80% realizado e 100% previsto.
- O AWS Budgets apenas notifica. Ele nao desliga recursos. A disciplina de
  destruir o ambiente e o controle principal; o alerta e a segunda linha de defesa.

## Convencao de tags

Todo recurso cobravel carrega estas quatro tags:

| Chave | Valor | Proposito |
|---|---|---|
| project | aws-reliability-lab | filtrar o gasto deste laboratorio no Cost Explorer |
| env | lab | separar de qualquer ambiente futuro parecido com producao |
| owner | @phantasmagorie | responsabilidade |
| managed-by | cloudformation \| terraform \| console | achar o que foi criado manualmente |

A tag managed-by e a mais importante: qualquer recurso marcado como console foi
criado fora da infraestrutura como codigo e nao sera removido por um teardown de stack.

## Principais geradores de custo (us-east-1, sob demanda, precos de tabela aproximados)

| Recurso | Enquanto ligado | Observacao |
|---|---|---|
| NAT Gateway | ~USD 0,045/h + trafego | cobra a cada hora que existe |
| Application Load Balancer | ~USD 0,023/h + uso | igual |
| RDS db.t4g.micro | ~USD 0,016/h single-AZ | armazenamento cobra mesmo com a instancia parada |
| ECS Fargate, 2 tarefas pequenas | ~USD 0,025/h no total | por tarefa em execucao |

Stack completa ligada: aproximadamente USD 0,12-0,18 por hora. Uma sessao curta
custa centavos, enquanto um ambiente esquecido ligado por um mes custa duas ordens
de grandeza a mais. Essa diferenca e todo o argumento da politica de destruicao abaixo.

Valores a verificar na AWS Pricing Calculator antes da Fase 1.

## Politica de destruicao

- Nenhuma sessao termina sem uma decisao de destruir, registrada em PROJECT_STATE.md.
- Verificar apos o teardown: nenhum NAT Gateway, nenhum load balancer, nenhuma
  instancia RDS, nenhum Elastic IP alocado.
- Qualquer coisa mantida ligada de proposito fica listada em PROJECT_STATE.md com o motivo.

## Sizing and lifetime rules

Adopted 2026-08-19, after a t3.micro was proposed for a workload that only had to run
an SSM agent and a curl. A t3.nano was correct and cost half.

- Every instance type, storage size and resource count carries a written justification
  against the actual workload. Selecting a familiar default without that justification
  is treated as an unjustified cost.
- The cheapest option that satisfies the requirement is the proposal. A more expensive
  option appears only with a named technical reason.
- A billable resource exists only for the duration of the test that needs it. Nothing
  stays running because it will be useful later.
- Expensive resources are shared across a single test window rather than created once
  per test. Grouping the M1 reachability tests and the route failure drill into one
  window cost USD 0.021 in total.

## Regras de dimensionamento e tempo de vida

Adotadas em 2026-08-19, depois de uma t3.micro ter sido proposta para uma carga que so
precisava executar um agente SSM e um curl. A t3.nano era a escolha correta e custava
metade.

- Todo tipo de instancia, tamanho de armazenamento e quantidade de recurso carrega uma
  justificativa escrita contra a carga real. Escolher um padrao familiar sem essa
  justificativa e tratado como custo injustificado.
- A opcao mais barata que atende ao requisito e a proposta. Uma opcao mais cara aparece
  apenas com uma razao tecnica nomeada.
- Um recurso cobravel existe apenas durante o teste que precisa dele. Nada fica ligado
  porque sera util depois.
- Recursos caros sao compartilhados dentro de uma unica janela de teste em vez de
  criados uma vez por teste. Agrupar os testes de alcance do M1 e o drill de falha de
  rota em uma janela custou USD 0,021 no total.

## M1 measured cost

| Window | Duration | Resources | Cost |
|---|---|---|---|
| First NAT trial | 12 min | NAT, Elastic IP | USD 0.010 |
| Test window | 20 min | NAT, Elastic IP, 2x t3.nano | USD 0.021 |
| **M1 total** | | | **USD 0.031** |

Free for the whole milestone: VPC, six subnets, internet gateway, four route tables,
three security groups, one IAM role and instance profile.

## Sizing and lifetime rules

Adopted 2026-08-19, after a t3.micro was proposed for a workload that only had to run
an SSM agent and a curl. A t3.nano was correct and cost half.

- Every instance type, storage size and resource count carries a written justification
  against the actual workload. Selecting a familiar default without that justification
  is treated as an unjustified cost.
- The cheapest option that satisfies the requirement is the proposal. A more expensive
  option appears only with a named technical reason.
- A billable resource exists only for the duration of the test that needs it. Nothing
  stays running because it will be useful later.
- Expensive resources are shared across a single test window rather than created once
  per test. Grouping the M1 reachability tests and the route failure drill into one
  window cost USD 0.021 in total.

## Regras de dimensionamento e tempo de vida

Adotadas em 2026-08-19, depois de uma t3.micro ter sido proposta para uma carga que so
precisava executar um agente SSM e um curl. A t3.nano era a escolha correta e custava
metade.

- Todo tipo de instancia, tamanho de armazenamento e quantidade de recurso carrega uma
  justificativa escrita contra a carga real. Escolher um padrao familiar sem essa
  justificativa e tratado como custo injustificado.
- A opcao mais barata que atende ao requisito e a proposta. Uma opcao mais cara aparece
  apenas com uma razao tecnica nomeada.
- Um recurso cobravel existe apenas durante o teste que precisa dele. Nada fica ligado
  porque sera util depois.
- Recursos caros sao compartilhados dentro de uma unica janela de teste em vez de
  criados uma vez por teste. Agrupar os testes de alcance do M1 e o drill de falha de
  rota em uma janela custou USD 0,021 no total.

## M1 measured cost

| Window | Duration | Resources | Cost |
|---|---|---|---|
| First NAT trial | 12 min | NAT, Elastic IP | USD 0.010 |
| Test window | 20 min | NAT, Elastic IP, 2x t3.nano | USD 0.021 |
| **M1 total** | | | **USD 0.031** |

Free for the whole milestone: VPC, six subnets, internet gateway, four route tables,
three security groups, one IAM role and instance profile.
