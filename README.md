# Replicar un paper de punta a punta con un agente

Artefactos completos de una charla sobre uso de IA en tareas complejas (UNR).
El caso de uso es real: reproducir de cero el análisis de alpha-diversidad de
[Scientific Reports 2024](https://www.nature.com/articles/s41598-024-77864-y),
usando el repo público de los autores, y después correr el pipeline validado
sobre muestras de suelo nuevas.

Todo lo que hay acá salió de un único pedido inicial a un agente. Están los
prompts, las salidas, los scripts que efectivamente corrieron, las tablas de
resultados y las notas — incluidas las conclusiones que resultaron equivocadas.

## El hallazgo

La primera reproducción falló de una forma consistente: las métricas ponderadas
por abundancia daban 91–112% del valor publicado, pero las de riqueza caían a
45–68%, con el mismo patrón en las cinco muestras.

Se probaron cinco hipótesis. Cuatro se descartaron; una era la causa:

**`qiime deblur denoise-16S --p-min-reads` (default 10) filtra sobre la tabla
agrupada de toda la corrida, no por muestra.** El paper corrió las 308 muestras
de `18_mixed` en un solo batch; nosotros corrimos 5. Un ASV con dos o tres reads
pasa un umbral de 10 sumado sobre 308 muestras y no lo pasa sumado sobre 5. La
misma muestra, los mismos reads y el mismo comando dan otra riqueza según qué
*otras* muestras estaban en la corrida.

Corriendo el batch completo de 308 con el default intacto:

| métrica | corrida de 5 | corrida de 308 |
|---|---|---|
| observed_features | 56–68% | 148/308 exactas, resto 100,0–102,7% |
| shannon | 91–93% | 100,00–100,83% |
| berger_parker_d | 106–112% | 98,4–100,0% |
| faith_pd | 45–60% | media 100,9%, disperso a ambos lados |

Las 5 muestras auditadas dan exacto: 72/66/98/85/124, con Shannon y
Berger-Parker coincidiendo a 15–16 cifras significativas.

Nada de esto necesitó información que el paper no publicara. El repo daba el
script, las accesiones y los parámetros, y `dataset_summary/18_mixed.tsv` dice
`count = 308.0` en la cara. Lo que faltaba era un valor por default más saber
que la composición del batch era determinante — por eso nadie lo anotó y nadie
lo preguntó.

### Lo que quedó abierto

Faith's PD no puede reproducir bit a bit: su filogenia se reconstruye de cero en
cada corrida (MAFFT/FastTree, no determinista). El sesgo sistemático desapareció
y el residuo es dispersión simétrica, o sea una propiedad de la métrica.

160 de las 308 muestras traen entre 1 y 5 features de más (nunca de menos), y
esas features viven justo en el umbral (mediana de 12 reads globales, 88% por
debajo de 20). La explicación candidata es que bajamos de los mirrors
`fastq.gz` de ENA y el paper usó `sra-tools`, que pueden diferir por unos pocos
reads. **Está sin probar** y así figura.

## Qué hay en cada carpeta

| carpeta | contenido |
|---|---|
| `prompts/` | El prompt y la salida de cada paso, uno por carpeta, en orden. |
| `pipeline/` | Los scripts que corrieron de verdad, uno por hipótesis, más los manifiestos. |
| `results/` | Tablas publicado-contra-reproducido de las cuatro corridas. |
| `figures/` | Figuras generadas desde los datos de las corridas. |
| `notes/` | Notas de trabajo, incluidas las conclusiones que después se refutaron. |

## Reproducir

Todo corre adentro del contenedor oficial de QIIME2, sin instalar nada en el host:

```bash
docker run --rm -v "$PWD/pipeline:/data" -w /data \
  quay.io/qiime2/qiime2-workshop:2026.7 bash /data/run_stool.sh
```

- `run_stool.sh` — la reproducción original, 5 muestras. Da corto en riqueza.
- `run_stool_full308.sh` — el batch completo del paper. Reproduce la tabla publicada.
- `run_stool_v2022.sh` — misma corrida en QIIME2 2022.2, la versión que cita el paper.
- `run_stool_dada2.sh` — DADA2 en lugar de Deblur.
- `run_stool_minreads1.sh` — 5 muestras con `--p-min-reads 1`.
- `run_atacama.sh` — el dataset de suelo del desierto de Atacama.

Los reads crudos no están versionados acá: se bajan de ENA con los manifiestos
de `pipeline/`. Los directorios de trabajo tampoco (son del orden del GB).

## Nota sobre las notas

`notes/validacion-NOTES.md` contiene dos conclusiones que resultaron falsas, y
se conserva sin editar. `notes/SUBAGENT-FINDINGS.md` las refuta y documenta la
causa real. Ese contraste es deliberado: la diferencia entre una hipótesis que
se probó y una que se dio por buena leyendo una columna de stats es el tema de
la charla.

## Créditos

El paper y el repo original son de sus autores; acá solo se los reproduce.
El dataset de suelo es el tutorial oficial de Atacama del proyecto QIIME2.
