# cloudformation-ap-build
Cloudformation build for Assembly Payments application solution design exercise

* Fork the public repo of the app (https://github.com/AssemblyPayments/simple-go-web-app)
  * Repo has been forked and new code added to accomidate for database connectivity. https://github.com/nikskiz/simple-go-web-app
Use Linux Instances (We don't use Windows)
  * Used ECS Solution (AWS Linux Based)
Using AWS Cloudformation, automate the deployment of the app addressing security, cost optimisation, availability and reliability
  * Cloudformation has been the choose of technology and the templates have been divided into different stacks
    * VPC Stack - This stack deploys a VPC with a CIDR address of 172.20.0.0/23
    * Security Group Stack - This stack was deployed as an attempt to centralize security groups, however later down the track there were issues when trying to add more security groups. You may notice some stacks include their own security groups
    * RDS Stack - This stack seperates the application from the database. This will create a postgresSQL server in the private subnets.
     * Improvements can be made to encrpyt the database.
    * LoadBalancer Stack - This stack is creating the detault target group and listener. The listener will be update for the ECS solution in the below stacks.
     * Improvements can be to redirect HTTP to HTTPS with a certificate installed via ACM and R53 to approve the certification in an automated fashion.
    * ECR Stack - This stack will create the repository for the docker image.
    * ECS Stack - This create the cluster which defines the instances. This stack will assoicate the cluster to the LB target group created above. The AMI is specific is the latest ECS AMI by AWS. A recommendation would be to manage a bootstrapped AMI and release with a CICD platform.
     * Improvements can be to use FARGATE as a managed instance service rather than managing the instances yourself.
    * ECS Service Stack - This stack will provision the service and define the task definitions which will run as tasks in the cluster. It utilizes the ECR image repository.
Ensure that the web servers are available in at least two(2) AWS availability zones and will automatically re balance themselves if there is
no healthy web server instance in either availability zone.
Redirect any HTTP requests to HTTPS.
