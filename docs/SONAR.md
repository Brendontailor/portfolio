# SonarQube Cloud

**Projeto:** `Brendontailor_portfolio`
**Organizacao:** `brendontailor`
**Servidor:** https://sonarcloud.io

## Como verificar

`powershell
# resumo do quality gate e das issues abertas
.\scripts\sonar-check.ps1

# analise local de segredos
sonar analyze secrets .
`

A analise completa roda no CI (`.github/workflows/sonar.yml`) a cada push
na branch principal e a cada pull request. O secret `SONAR_TOKEN` ja esta
gravado no repositorio.

## Politica de triagem

| Regra | Decisao |
| ----- | ------- |
| Arquivo de referencia, fora do build | Excluir em `sonar.exclusions` e marcar as issues antigas como falso positivo |
| Falso positivo legitimo | `//NOSONAR` **com justificativa na mesma linha** |
| Issue real | Corrigir no codigo e deixar a proxima analise fechar |
| Codigo de terceiro / gerado | Excluir e registrar o motivo em `docs/SONAR.md` |

## Cobertura

O workflow gera o relatorio de cobertura da stack detectada:

| Stack | Comando | Propriedade |
| ----- | ------- | ----------- |
| Go | `go test -coverprofile=coverage.out ./...` | `sonar.go.coverage.reportPaths` |
| Node (jest/vitest) | `npx <runner> --coverage` | `sonar.javascript.lcov.reportPaths` |
| Python | `pytest --cov=. --cov-report=xml` | `sonar.python.coverage.reportPaths` |
| Java | `mvn -B verify` | `sonar.coverage.jacoco.xmlReportPaths` |
| PHP | `vendor/bin/phpunit --coverage-clover` | `sonar.php.coverage.reportPaths` |

## PendenciasPadrao

- O quality gate ainda nao tem condicoes: configure em
  *Administration -> Quality Gate* (sem blocker novo, cobertura de new code
  >= 80%, duplicacao de new code <= 3%).
- A analise via CI substitui a Automatic Analysis para este projeto.