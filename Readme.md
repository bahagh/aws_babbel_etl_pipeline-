# Diagram :




![ddd drawio](https://github.com/bahagh/aws_babbel_etl_pipeline-/assets/73429122/2682c7a2-74ef-4f13-af93-9c1272586870)





# Technologies chosen:


### AWS Lambda: 
Is a serverless computing service that executes code in response to events, enabling scalability and cost-effectiveness without the need for server management. I used it to decode the events coming from the kinesis data stream , make the necessary transformations to them then  to save them as loads in the s3 bucket with a meaningful and easy access logic 

### AWS S3 Bucket : 
Is a scalable and durable object storage service for storing and retrieving data, commonly utilized for backup, archival, and static website hosting. I used it to store the processed events 

### Amazon Kinesis Data Streams : 
Is a real-time data streaming service designed for building applications that process and analyze streaming data, offering scalability and seamless integration with other AWS services. I used it to ingest real time event data

### AWS CloudWatch : 
Is a service that provides monitoring and observability of the AWS resources and applications in real time. Used it as a monitoring tool for the different aws services i've used

### Amazon DynamoDB : 
Is a fully managed NoSQL database service providing seamless scalability, high availability, and low-latency performance for flexible data models. I got use of it in handling duplicate events like a cache in such way u stored the uuid’s of processed events in it to be able to distinguish them from the events which were not processed yet and to skip them in case they have already been processed

### Terraform : 
Is an open-source Infrastructure as Code (IaC) tool that allows you to define and manage cloud and on-premises resources in human-readable configuration files. It enables you to automate the provisioning and management of infrastructure resources. In my CI/CD pipeline I chose terraform to assure the continuous deployment and delivery of the infrastructure of my ETL pipeline to the different aws services

### GitHub Actions: 
Is a Continuous Integration/Continuous Delivery (CI/CD) platform that makes it possible to automate your software development workflows right in the Github repository. It enables you to build, test, and deploy your code, In my case I chose it as a tool to automate the different steps of my cicd pipeline , in addition to that it is much simpler to integrate and to attach to the project github repository than other alternatives like (Jenkins for example )


# Design Questions:


- ## Handling duplicate events and quality metrics : 

  We can use the event\_uuid field to identify duplicate events. If an event with the same UUID has already been processed, we can ignore the duplicate. As for quality metrics, we could track the number of events processed, the number of duplicates, and the number of events of each type.

- ## Data Partitioning for performance ensuring and proposed solution in case the amount events are either 1000 higher or 1000 lower :

  We could partition the data by event\_type and created\_datetime. This would can allow us to quickly access all events of a certain type or all events from a certain time period, and if the amount of events is 1000 times smaller or bigger, this partitioning scheme would still work but I would consider adjusting the number of shards in the Kinesis stream and the size of my S3 bucket.

- ## Proposed data format :

  JSON would be a good format to store the data, as it is flexible and widely used. It allows for easy addition of new fields, which is important as the payload of the events can vary depending on the event type. However, if we would need to perform much complex queries on the data, a format like Parquet might be more efficient.


# Run Solution:

Assuming that you have already installed terraform in your machine and that it's path is already in the environment variables and your machine have aws cli installed as well.

Get into somewhere where you would like to save my projects and open a cmd or powershell and please follow these commands:

```bash
 mkdir Solution_Of_Baha
```

```bash
 cd Solution_Of_Baha
```

Clone the repository : 
```bash
 git clone https://github.com/bahagh/aws_babbel_etl_pipeline-.git
```

Get into the repository :
```bash
 cd aws_babbel_etl_pipeline-
```
Use this command to configure your access and secret aws account key , if other inputs were asked please press enter for default: 

```bash
aws configure 
```
### N.B : Please open terraform file "main.tf" in an editor and replace the 'account_id' with your own and save it before moving to the next step (check first line of the main.tf file ")

initialize terraform in the repository :
```bash
 terraform init 
```

plan changes :
```bash
 terraform plan 
```

apply changes : 
```bash
 terraform apply
```

#### And that's it the Event Processing Pipeline is set , please visit your aws console to check and test :) !
