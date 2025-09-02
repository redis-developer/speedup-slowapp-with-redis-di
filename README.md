# Don't let slow apps ruin your business!

Developers often use disk-based databases (PostgreSQL, MongoDB, and Oracle) as the single source of truth for data because they offer widely adopted programming models. However, despite their popularity, most suffer from one fundamental problem—the database becomes slower as more data is stored. To mitigate this problem, [Redis](https://redis.io/open-source) is often used as a cache layer to speed up read queries and considerably offload the database load. This approach helps companies to save money by eliminating the use of expensive read replicas. But how do we continuously move the data from the database to Redis without writing tons of code, using different distributed systems, and wasting lots of time?

![Streaming data with RDI!](/images/architecture.png "Streaming data with RDI")

You can use [Redis Data Integration (RDI)](https://redis.io/data-integration) for this. RDI updates Redis with any changes made in a source database, using a [Change Data Capture (CDC)](https://en.wikipedia.org/wiki/Change_data_capture) mechanism. RDI is designed to support apps that use a disk-based database as the system of record, but it must also be fast and scalable. This is a common requirement for mobile, web, and AI apps with a rapidly growing number of users; the performance of the central database is acceptable at first, but it will soon struggle to handle the increasing demand without a cache.

This repository demonstrates how to install, deploy, and use RDI with a fairly realistic use case. You start with a [PostgreSQL](https://www.postgresql.org) database running on-premises containing data from an e-commerce, and you use RDI to continuously move data to a Redis database running on [Redis Cloud](https://redis.io/cloud).

## 📋 Requirements

 * Docker: https://docs.docker.com/get-started/get-docker
 * Kubernetes: https://kubernetes.io/releases/download
 * Helm charts: https://helm.sh/docs/intro/install
 * Terraform: https://developer.hashicorp.com/terraform/install
 * Redis Insight: https://redis.io/insight
 * Redis Cloud: https://redis.io/try-free

## 🚀 Deploying RDI

To deploy RDI, you'll need a Kubernetes (K8S) cluster. This workflow ensures all dependencies (Ingress, database, and RDI) are managed and deployed in the correct order, with secure configuration and easy cleanup. Though you can use any K8S distribution, you don't quite need a production-ready K8S cluster. Any local K8S deployment will suffice. Development clusters of K8S, like [Minikube](https://minikube.sigs.k8s.io/docs/start), [K3S](https://k3s.io), or [Docker Desktop](https://docs.docker.com/desktop/features/kubernetes), will do just fine.

Once your K8S cluster is ready, deployment is automated using shell scripts in the `rdi-deploy` folder.


### 1. 🏠 Running RDI on K8S with a local database

This option deploys RDI on K8S along with its backend database. This is ideal if you want an all-inclusive installation of RDI. This option also saves you from spinning up a database on Redis Cloud, which can incur costs.

To deploy RDI with a local database, open a terminal and run:

```sh
cd rdi-deploy
./rdi-deploy-localdb.sh
```

This script will:

- Install the NGINX ingress controller using Helm
- Create the `rdi` namespace in your K8S cluster
- Deploy Redis Enterprise and custom resources
- Deploy the RDI database and wait for it to be ready
- Download the RDI Helm chart if not present already
- Extract connection details from Kubernetes secrets
- Generate a secure JWT key to be used with RDI API
- Create a custom `rdi-values.yaml` for Helm deployment
- Install RDI using Helm with the generated values

To monitor the deployment:

```sh
helm list -n rdi
```

You should see the following output:

```sh
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
default rdi             1               2025-08-31 20:41:59.929005297 +0000 UTC deployed        pipeline-0.0.0  0.0.0      
rdi     rdi             1               2025-08-31 16:41:47.254181 -0400 EDT    deployed        rdi-1.14.0
```

List the deployed pods to check their statuses:

```sh
kubectl get pod -n rdi
```

You should see an output similar to this:

```sh
NAME                                    READY   STATUS    RESTARTS   AGE
collector-api-66f58f58c7-w96qm          1/1     Running   0          69s
rdi-api-76f894cc77-lg99q                1/1     Running   0          78s
rdi-metrics-exporter-6656695547-b76tm   1/1     Running   0          78s
rdi-operator-7c994f8fc8-gscmf           1/1     Running   0          78s
rdi-reloader-546c9cd849-2d8kk           1/1     Running   0          78s
```

To undeploy and clean up all resources, run:
```sh
cd rdi-deploy
./rdi-undeploy-localdb.sh
```

### 2. ☁️ Running RDI on K8S with a database on Redis Cloud

This option deploys RDI on K8S and a backend database running on Redis Cloud. This is ideal if you want an RDI installation with a database that can scale to your needs, especially if you plan to extend this workload to perform intensive data processing from a source database.

Before using this option, you need to make sure to:

1. [Create an Redis Cloud account](https://redis.io/docs/latest/operate/rc/rc-quickstart/#create-an-account) if you don't have one. Note that creating an account takes only 5 minutes.
2. [Create Redis Cloud API keys](https://redis.io/docs/latest/operate/rc/api/get-started/enable-the-api) and make them available as environment variables before running the script.
3. [Set your payment methods](https://redis.io/docs/latest/operate/rc/billing-and-payments/#add-payment-method) in your account. You won't be charged until you create a database.

To make your Redis Cloud API keys available as environment variables, you must export the following ones:

```sh
export REDISCLOUD_ACCESS_KEY=<THIS_IS_GOING_TO_BE_YOUR_API_ACCOUNT_KEY>
export REDISCLOUD_SECRET_KEY=<THIS_IS_GOING_TO_BE_ONE_API_USER_KEY>
```

You also need to customize some Terraform variables. Please update the file [rdi-deploy/terraform.tfvars](./rdi-deploy/terraform.tfvars) and change the values of the following variables:

* payment_card_type
* payment_card_last_four
* essentials_plan_cloud_provider
* essentials_plan_cloud_region

Everything else you can leave unchanged, unless you want to change them as well. Once you have done this, open a terminal and run:

```sh
cd rdi-deploy
./rdi-deploy-clouddb.sh
```

This script will:

- Install the NGINX ingress controller using Helm
- Create the `rdi` namespace in your K8S cluster
- Initialize and apply Terraform to create a Redis Cloud database
- Download the RDI Helm chart if needed
- Extract connection details from Terraform outputs and variables
- Generate a secure JWT key to be used with RDI API
- Create a custom `rdi-values.yaml` for Helm deployment
- Install RDI using Helm with the generated values

To monitor the deployment:

```sh
helm list -n rdi
```

You should see the following output:

```sh
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
default rdi             1               2025-08-31 20:41:59.929005297 +0000 UTC deployed        pipeline-0.0.0  0.0.0      
rdi     rdi             1               2025-08-31 16:41:47.254181 -0400 EDT    deployed        rdi-1.14.0
```

List the deployed pods to check their statuses:

```sh
kubectl get pod -n rdi
```

You should see an output similar to this:

```sh
NAME                                    READY   STATUS    RESTARTS   AGE
collector-api-66f58f58c7-w96qm          1/1     Running   0          69s
rdi-api-76f894cc77-lg99q                1/1     Running   0          78s
rdi-metrics-exporter-6656695547-b76tm   1/1     Running   0          78s
rdi-operator-7c994f8fc8-gscmf           1/1     Running   0          78s
rdi-reloader-546c9cd849-2d8kk           1/1     Running   0          78s
```

To undeploy and clean up all resources, run:
```sh
cd rdi-deploy
./rdi-undeploy-clouddb.sh
```

## 🐘 Running the source database

This project contains a [PostgreSQL](https://www.postgresql.org) database with an e-commerce dataset that will be used as source data. You must get this database up and running to play with this demo. In the folder `source-db`, you will find a Docker Compose file that will spin up the database and load with data, as well as an instance of [pgAdmin](https://www.pgadmin.org) you can use to access the database.

1. Open a terminal and navigate to the `source-db` directory:

	```sh
	cd source-db
	```

2. Start the database and pgAdmin services:

	```sh
	docker compose up -d
	```

	This will:
	- Start a PostgreSQL container with Debezium support
	- Load initial data from `scripts/initial-load.sql`
	- Expose the PostgreSQL database over the port `5432`
	- Start pgAdmin on port `8888` (web interface)

3. Verify the containers are running:

	```sh
	docker compose ps
	```

4. Access pgAdmin in your browser at [http://localhost:8888](http://localhost:8888)

	- Email: `admin@postgres.com`
	- Password: `pgadmin4pwd`

5. The PostgreSQL database is accessible at:

	- Host: `localhost`
	- Port: `5432`
	- User: `postgres`
	- Password: `postgres`
	- Database: `postgres`

Once you have done with this demo, you can stop the services:

```sh
docker compose down
```

## 🎯 Running the target database

The target database will be the Redis database, which will receive the data from RDI. In this use case, the target database represents the database from which your application will read the data, regardless of whether the data was written into the PostgreSQL database. You are going to create this database on Redis Cloud using Terraform. The target database is slightly different from the one used by RDI. It requires fewer resources and doesn't need persistence enabled. For this reason, the Terraform code used will not require a paid database on Redis Cloud; it will use the free plan available for all Redis Cloud users.

To create the target Redis database:

1. Open a terminal and navigate to the `target-db` directory:

	```sh
	cd target-db
	```

2. Edit the file [target-db/terraform.tfvars](./target-db/terraform.tfvars) and update the variables `essentials_plan_cloud_provider` and `essentials_plan_cloud_region` with the options of your choice.

3. Initialize Terraform:

	```sh
	terraform init
	```

4. Apply the Terraform configuration to create the database:

	```sh
	terraform apply -auto-approve
	```

5. After completion, you can view the connection details:

	```sh
	terraform output
	```

	This will show the host and port from your new target database.

Once you have done with this demo, you can destroy the database:

```sh
terraform destroy -auto-approve
```

## ⚡ Using RDI for data streaming

Now that everything has been properly deployed, you can start the fun part—using RDI to stream database changes from the source database to the target database.

In this section, you will:

* Investigate your current dataset using pgAdmin.
* Use Redis Insight to access your RDI deployment.
* Deploy a RDI pipeline to stream data to Redis.
* Use Redis Insight to verify if data is available.

Open a browser and point to `http://localhost:8888`.

![pgAdmin login!](/images/pgAdmin-login.png "pgAdmin login")

Login using:

* Email: `admin@postgres.com`
* Password: `pgadmin4pwd`

Once you have logged in, you will access the object explorer. The first time you access the object explorer you will need to register the source database. Use the following values to register:

- Host: `postgres` (This is not a typo. Here you should not use `localhost`)
- Port: `5432`
- User: `postgres`
- Password: `postgres`

Then, navigate to Postgres > Databases > postgres > Schemas > public > Tables. You should see the following tables:

![Postgres tables!](/images/pgAdmin-view-data.png "Postgres tables")

This means you are ready to start the data streaming process. Open Redis Insight, then click on `Redis Data Integration`. You should see the following screen:

![RDI wizard!](/images/ri-empty-rdi.png "RDI wizard")

Click in the `Add RDI Endpoint` button. The folllowing screen will show up:

![RDI endpoint!](/images/ri-rdi-endpoint.png "RDI endpoint")

Fill the screen with the values shown in the picture above. As for the password, you can retrieve what password to set in the file `rdi-deploy/rdi-values.yaml`. The value set in the `connection.password` field is what you should use to register the RDI endpoint. Please note that the file `rdi-deploy/rdi-values.yaml` is created when you deploy RDI. If this file doesn't exist, return to the section [Deploying RDI](#-deploying-rdi).

Once you access your RDI endpoint, you can start the configuration of your pipeline. For this step, you can use the code available at the file [pipeline-config.yaml](./pipeline-config.yaml). You should add this code to the pipeline editor.

![Pipeline configuration!](/images/ri-new-pipeline.png "Pipeline configuration")

Replace the values of the variables `${REDIS_DATABASE_HOST}` and `${REDIS_DATABASE_PORT}` with the values from the target database you created on Redis Cloud. You can retrieve these values in your Redis Cloud account using the console. However, an easiest way is by running the command `terraform output` in the `target-db` folder. You should see an output similar to this:

```sh
redis_database_host = "redis-00000.c84.us-east-1-2.ec2.redns.redis-cloud.com"
redis_database_port = "00000"
```

Once you have finished updating the variables, go ahead and deploy the pipeline. This process may take a few minutes, as RDI performs an initial snapshot of the source database to create a data stream for each table found and start the streaming. Once the process finishes, you should be able to navigate to the `Pipeline Status` tab to check the status of your pipeline.

![Pipeline status!](/images/ri-pipeline-status.png "Pipeline status")

The pipeline should report `78 records` inserted into the target database and a unique counter for each source table viewed as a data stream. This means your RDI deployment is working as expected. At this point, whatever data you write into the source database will instantly stream to Redis. You can verify this by accessing your target database in Redis Cloud.

Access your database using the Redis Cloud console. Then click `Connect` and `Open in desktop`.

![TargetDB connect!](/images/targetdb-connect.png "TargetDB connect")

This should open your target database on Redis Insight, allowing you to visualize your data.

![TargetDB data!](/images/targetdb-data.png "TargetDB data")

These `78 keys` represents the initial snapshot RDI performs in the source database to create the respective data streams. Once created, any data written in the source database should emit an event that RDI will capture and stream into the target database. This includes any **INSERT**, **UPDATE**, and **DELETE** operations. To verify this, you can use the script [demo-multiple-users.sql](./demo-multiple-users.sql) that adds roughly `50` users into the table `user`.

## ⚙️ Adding transformation jobs

One cool feature of RDI that you can leverage is the ability to transform data as it is streamed into the target database. You can create one or more [job files](https://redis.io/docs/latest/integrate/redis-data-integration/data-pipelines/transform-examples/) that will be used along with the data pipeline during the data streaming. Let's practice this with one example.

First, go to Redis Insight and stop and reset your data pipeline. This will allow you to change your data pipeline without streaming any data. Click the plus sign under `Add transformation jobs` in `Pipeline Management`. Name this job `custom-job` and define it using the code available in the file [custom-job-v2.yaml](./custom-job-v2.yaml).

![Custom job!](/images/ri-custom-job.png "Custom job")

This job performs three operations, all related to the `user` table. First, it changes the data's output from [Hashes](https://redis.io/docs/latest/develop/data-types/hashes) to [JSON](https://redis.io/docs/latest/develop/data-types/json). Second, it adds a new field into the target called `display_name` that will have as its value the values `first_name` and `last_name` concatenated. Third, it will add another field called `user_type` with two possible values: `internal` or `external`, depending on the user's email hostname.

Let's verify this. On Redis Insight, start your data pipeline again so any new data can be streamed into the target. Now use the script [demo-add-user.sql](./demo-add-user.sql) to insert a new row into the table `user`. Once you execute that script, check Redis Insight and observe the keys from your target database. You should have a new key with a JSON version of the user.

![New JSON key!](/images/ri-new-json-key.png "New JSON key")

However, the user type is still `internal` as their email contains `@example.com.` Let's change the email in the source table to trigger the update and the execution of the job transformation. Go ahead and use the script [demo-modify-user.sql](./demo-modify-user.sql) to update the user's email. You may need to identify which `id` is associated with the user before running the script, as you may need to update the **WHERE** clause of the SQL statement. Once you execute the script, you should immediately see the update in the target database.

![User type!](/images/ri-user-type.png "User type")

## License

This project is licensed under the **[MIT license](LICENSE)**.
