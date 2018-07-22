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
Ensure that the web servers are available in at least two(2) AWS availability zones and will automatically re balance themselves if there is
no healthy web server instance in either availability zone.
Redirect any HTTP requests to HTTPS.
