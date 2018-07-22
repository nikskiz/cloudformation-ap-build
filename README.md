# cloudformation-ap-build
Cloudformation build for Assembly Payments application solution design exercise

## Running the Scripts
Packages required to be installed
 * AWS CLI
 * Docker

Ensure that you have configured your linux instance with AWS credentials. This can be tested via
`aws ec2 describe-instances`

Clone the repository and run the following
`sudo bash build-cf-stacks.sh`
NOTE: reuqired to use `sudo`

# Base Requirements

* Fork the public repo of the app (https://github.com/AssemblyPayments/simple-go-web-app)
  * Repo has been forked and new code added to accomidate for database connectivity. https://github.com/nikskiz/simple-go-web-app

Use Linux Instances (We don't use Windows)
  * Used ECS Solution (AWS Linux Based)

Using AWS Cloudformation, automate the deployment of the app addressing security, cost optimisation, availability and reliability
  * Cloudformation has utilized and the templates have been divided into different stacks
    * VPC Stack - This stack deploys a VPC with a CIDR address of 172.20.0.0/23
    * Security Group Stack - This stack was deployed as an attempt to centralize security groups, however later down the track there were issues when trying to add more security groups. You may notice some stacks include their own security groups
    * RDS Stack - This stack separates the application from the database. This will create a postgresSQL server in the private subnets.
      * Improvements can be made to encrypt the database.
    * LoadBalancer Stack - This stack is creating the default target group and listener. The listener will be update for the ECS solution in the below stacks.
      * Improvements can be to redirect HTTP to HTTPS with a certificate installed via ACM and R53 to approve the certification in an automated fashion.
    * ECR Stack - This stack will create the repository for the docker image.
    * ECS Stack - This create the cluster which defines the instances in an ASG. This stack will associate the cluster to the LB target group created above. The AMI is specific is the latest ECS AMI by AWS. A recommendation would be to manage a bootstrapped AMI and release with a CICD platform.
      * Improvements can be to use FARGATE as a managed instance service rather than managing the instances yourself.
    * ECS Service Stack - This stack will provision the service and define the task definitions which will run as tasks in the cluster. It utilizes the ECR image repository. The stack also includes sending logs to cloudwatch (no need to login to servers to retrieve logs)
  
Ensure that the web servers are available in at least two (2) AWS availability zones and will automatically re balance themselves if there is no healthy web server instance in either availability zone.
 * The doc https://github.com/nikskiz/cloudformation-ap-build/blob/master/AWS%20ECS%20Solution.pdf outlines the solutions design which meets most of the 5 AWS pillars, which includes auto recovery.
   * Improvements that can be added to the stack are:
     * Private Hosted Zone, allows services such as RDS to be re-created if needed (I.E an RDS being restored will create a new CNAME)
     * ACM certificate to manage the hostname
     * Lambda functions to report on events to communications channels (i.e slack)
     * Application level monitoring and nice dashboards to follow
     * AWS Code Build/AWS Code Pipeline to provide easy deployments and automation in releases.
Redirect any HTTP requests to HTTPS.
 * Unfortunately didn't have time to redirect HTTP to HTTPS as this required ACM and route53, otherwise redirecting HTTP to HTTPS on a default loadbalancer will show a certificate error.
 
## Bonus
A cloud architecture diagram(s)
 * Can be found https://github.com/nikskiz/cloudformation-ap-build/blob/master/AWS%20ECS%20Solution.pdf 
 
AWS Code Build/AWS Code Pipeline to guarantee a repeatable deployment process
 * Unfortunately didn't have time
 
Use ECS
 * Achieved in the design
 
Add a Database to your automation and have your application serve the data stored there.
 * Achieved in the design
