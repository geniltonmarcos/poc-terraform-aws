import sys
from awsglue.transforms import Join
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import SparkSession

# Inicializa o contexto do Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Obtém as opções passadas para o script
args = getResolvedOptions(sys.argv, ['job_history_players'])

# Cria um dataframe a partir dos arquivos CSV
df1 = spark.read.option("header", "true").csv("s3://bucket-unprocessed/mbl_players.csv")
df2 = spark.read.option("header", "true").csv("s3://bucket-unprocessed/addresses.csv")

# Define as colunas para o join
join_keys = ["PlayerId"]

# Realiza o Left Join
joined_df = df1.join(df2, join_keys, "left")

# Escreve o resultado em um arquivo CSV no bucket de destino
joined_df.write.option("header", "true").csv("s3://bucket-processed/results.csv")

# Fim do script