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

DsAddresses = glueContext.create_dynamic_frame.from_options(format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"optimizePerformance":False,"separator":",","multiline":False}, connection_type = "s3", format = "csv", connection_options = {"paths": ["s3://bucket-unprocessed/addresses.csv"], "recurse":True}, transformation_ctx = "DsAddresses")

DsPlayers1 = glueContext.create_dynamic_frame.from_options(format_options = {"quoteChar":"\"","escaper":"","withHeader":True,"optimizePerformance":False,"separator":","}, connection_type = "s3", format = "csv", connection_options = {"paths": ["s3://bucket-unprocessed/mlb_players.csv"], "recurse":True}, transformation_ctx = "DsPlayers1")

DsPlayers1DF = DsPlayers1.toDF()
DsAddressesDF = DsAddresses.toDF()
Transform0 = DynamicFrame.fromDF(DsPlayers1DF.join(DsAddressesDF, (DsPlayers1DF['PlayerId'] == DsAddressesDF['PlayerId']), "left"), glueContext, "Transform0")

DataSink0 = glueContext.write_dynamic_frame.from_options(frame = Transform0, format_options = {"compression": "snappy"}, connection_type = "s3", format = "glueparquet", connection_options = {"path": "s3://bucket-glue-processed", "partitionKeys": []}, transformation_ctx = "DataSink0")
job.commit()

