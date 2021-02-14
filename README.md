# Basic Task
### HOW TO
```Before I start the description of I have achieved the goal I would like to say, that AWS ACCount URL was incorrectly sent to me. Not sure if this is a part of the test, but anyway figured it out too :)```

1. Under VPC service => Route teables => changed entry 0.0.0.0/2X to 0.0.0.0/0.
2. I have used System Manager and Session Manager to access machine. The docker container was stopped. I have started it. Then I have used "docker cp" command to get the /code to localhost
as I couldn't find any code on the Ubuntu machine.
3. The index.html I have changed into J2 template, and pushed to templates directory.
4. In docker-entrypoint.sh file I have added J2 command to resolve J2 envs in index.html.j2 to include SERVER name. Also added this value to environment section in docker-compose.yaml. I also created small script called start.sh. It sets SERVER and rebuilds docker containers. The script has been added to crontab.
5. Added an .env file to use with docker-compose.yaml. Additionally I have added MAINTENACE mode to it. Actually enabled it. Also added HEALTH stuff
6. I have made an image of recngx01 and called main-image.
7. I have created a second subnet with the name "andrzejs-subnet2" and put it into us-west-1a zone. I assigned "recruitment@candidate011" route table to it.
8. I have created Application Loadbalancer, target group and security group for ALB. The Target group looks for health check under following path: /elb-status.
The security group has only outbound set to port 80 and points to "recruitment@candidate011" security group. And in the "recruitment@candidate011" SG I have added port 80
in the inbound for ALB SG.
9. I launched second machine and named recngx02. I have registered it with target group. I didn't any additional tags besides the Name tag.


# Bonus Task No 1
1. Create separate subnets. One for only servers. This subnet will be behind NAT (set obviously Route Tables). The other public one will be used for application LB.
2. I already done this via sec groups, but always restrict inbound and outbound to sec groups not to IP (if possible). In ELB group set only to 443.
3. Enable HTTPS on the ALB (add listeners) - remeber about ciphers. Cert get either from AWS ACM or maybe use Letsencrypt or just buy it :) In the Listener setup add listener for port 80 and use it as redirection to 443. If needed we can add so path rules here.
4. Use NACL to restrict access to particular ports between particular subnets.
5. Add Autoscaling setup, so we could have High Availability
6. Docker images store in ECR, so we could actually use whatever AMI wcich will have docker installed.
7. Setup Route 53 with hosted zone where we could attach particular FQDN to our ALB. We could also set here the alarms or e.g. Failover if we want to use app in other region.

To be honest I recommend to push above from EC2 to ECS Fargate (but not based on EC2). Saves time on e.g. maintenance like upgradeing OS. Better and faster deployment.

Also we could store frontend files in S3 bucket and then serve it via Cloudfront which actually resolves the problem of servers maintenance and failover. It is realiable too. This could be a nice DDoS and Denial of Wallet solution.

# Bonus Task No 4
In the **main.tf** there is a section called: **Setup Cloudwatch Alarm**. Unfortunately, I can't add topic subscription as email, so this could be done manually. This is a simple setup of alarm which looks into HealthyHost metric. If we have below 2 working instance I will get notification. 
