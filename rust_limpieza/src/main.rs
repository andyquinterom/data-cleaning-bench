use polars::lazy::dsl::*;
use polars::prelude::*;

fn month_to_num(month: Expr) -> Expr {
    // Utilizamos la expresión de `month` y le aplicamos un mapeo
    month.map(
        // Esta función se aplica a cada pedazo de la serie
        |series| -> PolarsResult<Option<Series>> {
            let chunks: Int32Chunked = series
                // Convertimos la serie a una StringChunked
                // la cual contiene strings. Si ocurre un error
                // durante la lectura, retornamos el error con el signo `?`
                .str()?
                // Aplicamos a cada elemento del chunk una función
                // que convierte el mes a un número
                // Si el mes no es válido, retornamos None
                // el cual es un valor nulo en Polars
                .apply_generic(|month| match month? {
                    "Jan" | "January" | "01" | "1" => Some(1),
                    "Feb" | "February" | "02" | "2" => Some(2),
                    "Mar" | "March" | "03" | "3" => Some(3),
                    "Apr" | "April" | "04" | "4" => Some(4),
                    "May" | "05" | "5" => Some(5),
                    "Jun" | "June" | "06" | "6" => Some(6),
                    "Jul" | "July" | "07" | "7" => Some(7),
                    "Aug" | "August" | "08" | "8" => Some(8),
                    "Sep" | "September" | "09" | "9" => Some(9),
                    "Oct" | "October" | "10" => Some(10),
                    "Nov" | "November" | "11" => Some(11),
                    "Dec" | "December" | "12" => Some(12),
                    _ => None,
                });

            // Retornamos el resultado en forma de una nueva
            // serie que contiene los números de los meses.
            // El Ok(Some(...)) indica que la operación fue exitosa
            // y que el resultado es un valor Some(...)
            Ok(Some(chunks.into_series()))
        },
        GetOutput::default(),
    )
}

fn substr(expr: Expr, start: usize, end: usize) -> Expr {
    expr.map(
        move |s: Series| -> PolarsResult<Option<Series>> {
            let chunks: StringChunked = s.str()?.apply_generic(|s| match s {
                None => None,
                Some(s) => s.get(start..end),
            });
            Ok(Some(chunks.into_series()))
        },
        GetOutput::default(),
    )
}

const AIR_QUALITY_CSV: &str = "data/air_quality.csv";

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut schema = Schema::new();
    schema.with_column("month".into(), DataType::String);
    schema.with_column("day".into(), DataType::Int32);
    schema.with_column("year".into(), DataType::Int32);
    schema.with_column("hour".into(), DataType::Int32);
    schema.with_column("minute".into(), DataType::Int32);
    schema.with_column("ozone".into(), DataType::Int32);
    schema.with_column("solar_R".into(), DataType::Int32);
    schema.with_column("wind".into(), DataType::Float32);
    schema.with_column("temp".into(), DataType::Int32);
    schema.with_column("sensor_id".into(), DataType::String);

    let null_values = NullValues::AllColumns(vec!["NA".to_string(), "N/A".to_string()]);

    let df = LazyCsvReader::new(AIR_QUALITY_CSV)
        .has_header(true)
        .with_null_values(Some(null_values))
        .with_dtype_overwrite(Some(&schema))
        .finish()?
        .with_column(month_to_num(col("month")).alias("month"))
        // Combine the month, day and year to a single date column
        .with_column(
            datetime(
                DatetimeArgs::new(col("year"), col("month"), col("day"))
                    .with_hour(col("hour"))
                    .with_minute(col("minute"))
                    .with_time_unit(TimeUnit::Milliseconds),
            )
            .alias("date"),
        )
        .sort("date", Default::default())
        .group_by([col("sensor_id")])
        .agg([
            col("ozone")
                .fill_null_with_strategy(FillNullStrategy::Backward(None))
                .fill_null_with_strategy(FillNullStrategy::Forward(None)),
            col("solar_R")
                .fill_null_with_strategy(FillNullStrategy::Backward(None))
                .fill_null_with_strategy(FillNullStrategy::Forward(None)),
            col("wind")
                .fill_null_with_strategy(FillNullStrategy::Backward(None))
                .fill_null_with_strategy(FillNullStrategy::Forward(None)),
            col("temp")
                .fill_null_with_strategy(FillNullStrategy::Backward(None))
                .fill_null_with_strategy(FillNullStrategy::Forward(None)),
            col("date"),
        ])
        .explode([
            col("ozone"),
            col("solar_R"),
            col("wind"),
            col("temp"),
            col("date"),
        ])
        .with_columns([
            substr(col("sensor_id"), 0, 3).alias("airport"),
            substr(col("sensor_id"), 3, 6).alias("sensor_number"),
        ])
        .select([
            col("ozone"),
            col("solar_R"),
            col("wind"),
            col("temp"),
            col("date"),
            col("sensor_id"),
            col("airport"),
            col("sensor_number"),
        ]);

    let mut res = df.collect()?;

    CsvWriter::new(std::io::BufWriter::new(std::fs::File::create(
        "data/air_quality_rust.csv",
    )?))
    .finish(&mut res)?;

    Ok(())
}
