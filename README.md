# Benchmark

## Cómo correr el benchmark

Antes de correr el benchmark, es necesario instalar las siguientes dependencias:

1. Rust (cargo): https://www.rust-lang.org/tools/install
2. R (versión 4.1 o superior): https://cran.r-project.org/

Una vez instaladas las dependencias, se puede correr el benchmark con el siguiente comando:

```bash
Rscript bench.R
```

## Personalizar el benchmark

Se puede cambiar el número de sensores y el número de iteraciones del benchmark modificando las variables `n_sensors` y `n_iterations` en el archivo `bench.R`.
