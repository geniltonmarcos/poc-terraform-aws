import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

## @params: [JOB_NAME]
args = getResolvedOptions(sys.argv, ['JOB_NAME'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)
## @type: DataSource
## @args: [format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"optimizePerformance":False,"separator":",","multiline":False}, connection_type = "s3", format = "csv", connection_options = {"paths": ["s3://bucket-unprocessed/addresses.csv"], "recurse":True}, transformation_ctx = "DataSource0"]
## @return: DataSource0
## @inputs: []
DataSource0 = glueContext.create_dynamic_frame.from_options(format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"optimizePerformance":False,"separator":",","multiline":False}, connection_type = "s3", format = "csv", connection_options = {"paths": ["s3://bucket-unprocessed/addresses.csv"], "recurse":True}, transformation_ctx = "DataSource0")
## @type: DataSource
## @args: [format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"optimizePerformance":False,"separator":","}, connection_type = "s3", format = "csv", connection_options = {"paths": ["s3://bucket-unprocessed/mlb_players.csv"], "recurse":True}, transformation_ctx = "DataSource1"]
## @return: DataSource1
## @inputs: []
DataSource1 = glueContext.create_dynamic_frame.from_options(format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"optimizePerformance":False,"separator":","}, connection_type = "s3", format = "csv", connection_options = {"paths": ["s3://bucket-unprocessed/mlb_players.csv"], "recurse":True}, transformation_ctx = "DataSource1")
## @type: Join
## @args: [columnConditions = ["="], joinType = left, keys2 = ["PlayerId"], keys1 = ["PlayerId"], transformation_ctx = "Transform0"]
## @return: Transform0
## @inputs: [frame1 = DataSource1, frame2 = DataSource0]
DataSource1DF = DataSource1.toDF()
DataSource0DF = DataSource0.toDF()
Transform0 = DynamicFrame.fromDF(DataSource1DF.join(DataSource0DF, (DataSource1DF['PlayerId'] == DataSource0DF['PlayerId']), "left"), glueContext, "Transform0")
## @type: DataSink
## @args: [format_options = {"compression": "snappy"}, connection_type = "s3", format = "glueparquet", connection_options = {"path": "s3://bucket-glue-processed", "partitionKeys": []}, transformation_ctx = "DataSink0"]
## @return: DataSink0
## @inputs: [frame = Transform0]
DataSink0 = glueContext.write_dynamic_frame.from_options(frame = Transform0, format_options = {"compression": "snappy"}, connection_type = "s3", format = "glueparquet", connection_options = {"path": "s3://bucket-glue-processed", "partitionKeys": []}, transformation_ctx = "DataSink0")
job.commit()


# import sys
# from awsglue.transforms import Join
# from awsglue.context import GlueContext
# from awsglue.utils import getResolvedOptions
# from pyspark.context import SparkContext
# from pyspark.sql import SparkSession

# # Inicializa o contexto do Glue
# sc = SparkContext()
# glueContext = GlueContext(sc)
# spark = glueContext.spark_session

# # Obtém as opções passadas para o script
# args = getResolvedOptions(sys.argv, ['job_process_history_players'])

# # Cria um dataframe a partir dos arquivos CSV
# df1 = spark.read.option("header", "true").csv("s3://bucket-unprocessed/mlb_players.csv")
# df2 = spark.read.option("header", "true").csv("s3://bucket-unprocessed/addresses.csv")

# # Define as colunas para o join
# join_keys = ["PlayerId"]

# # Realiza o Left Join
# joined_df = df1.join(df2, join_keys, "left")

# # Escreve o resultado em um arquivo CSV no bucket de destino
# joined_df.write.option("header", "true").csv("s3://bucket-glue-processed/results.csv")

# # Fim do script