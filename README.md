# Kura Labs Cohort 5- Deployment Workload 4


---


## SYSTEM DIAGRAM
<div align="center">
<img width="821" alt="image" src="https://github.com/user-attachments/assets/ae8f2d4c-cc3b-4116-87af-f1abb15c376a">

</div>


## PURPOSE

In the previous workload, we explored how to build a multistage pipeline in Jenkins to implement CI/CD for the microblog application. However, the structure used was not the best practice for real-world industry projects. As the application source code, Jenkins, and monitoring tools were all aggregated into a single VPC. In this workload, we took a step closer to real-world web design architecture by using a custom VPC along with the default VPC in AWS to enhance the application’s security and availability. This is done in utilizing a version control system (GitHub) and an automation server (Jenkins) to implement a complete CI/CD pipeline. The actual application is separated into a properly configured custom VPC, with subnets and route tables associated with it. Finally, we use a separate server to monitor the application server, as in the previous practice, to ensure the application functions properly.
Be sure to document each step in the process and explain WHY each step is important to the pipeline.

## STEPS

### GitHub

1. Creating the repository. The repository contains the latest source code for building, testing, deploying, and running the application in production. Jenkins can then retrieve the code and implement the CI/CD pipeline.


### Costum VPC
2. A custom VPC is required in this practice to separate the production environment from the deployment environment. The custom VPC should have two subnets: one public subnet and one private subnet.

	a. The public subnet will be responsible for communicating with the internet through an internet gateway. In this case, the web server will be established in the public subnet, allowing access from all IPs (0.0.0.0/0).
	
	b. The private subnet is used to protect the backend of the application from direct access. The private subnet can communicate with the internet through the public subnet by using an NAT gateway (Network Address Translation) located in the public subnet, which allows instances in the private subnet and public subnet communicate using private IP addresses.
	
3. Set up route table for each subnet
   a. The route table associated with public subnet should have a rule to internet gateway then to internet and a rule that allow local communication.
   	<div align="center">
		<img width="678" alt="image" src="https://github.com/user-attachments/assets/9bf7ceab-4b2c-4d0a-96ef-12ad5894acd3">

	</div>

   b. The private route table has a rule to NAT gateway as well as the rule for local.
   	<div align="center">
		<img width="697" alt="image" src="https://github.com/user-attachments/assets/07d0e892-d7da-4a9c-9f6f-f4611c99fe19">

	</div>


### Servers  

4. Total four severs should be created, Jenkins server, Web server, Application server and Monitoring server.

   	a. Jenkins server is responsible for running Jenkins, which is being created in the default VPC. It is important for the availability of Jenkins pipeline. The security group for Jenkins server should open port 22 for SSH and port 8080 for running Jenkins.  
   
   	b. The web server is in the presentation layer and should allow direct access from the internet. Therefore, it is placed in the public subnet of the custom VPC. The security group for the web server opens port 22 for SSH and port 80 for HTTP. 
   		
 	In the Web Server, install NginX and modify the "sites-enabled/default" file so that the "location" section reads as below:
	```
	location / {
	proxy_pass http://<private_IP>:5000;
	proxy_set_header Host $host;
	proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	}
	```
	IMPORTANT: Be sure to replace `<private_IP>` with the private IP address of the application server. Run the command `sudo nginx -t` to verify. Restart NginX afterward. The configuration ensured that the web server havs Nginx set up as a reverse proxy to route all traffic from port 80 to Gunicorn, which is located on the application server to communicate with the application itself.

   	c. The application server in our case has application itself the database we will use. Based on the three-tier architecture, it is in the logical layer and data layer. Since data and source code should not be accessed by unauthorized sources, the server should be placed in the private subnet of the custom VPC. Traffic from Nginx to the application will be directed to port 5000, where Gunicorn is listening. The security group is configured to open port 22 for SSH and port 5000 for Gunicorn.  

   
### Keys

5. The application server is not in the public subnet. In order to access the resouces in Application_Server, we should SSH into it from the Web_Server which is in the same VPC. They can communicate with each other using private IP addresses. To SSH into the Appication_Server, the key pair of Application_Server should be stored properly. We can use the command

	```
	ssh -i /path/to/keypair.pem hostname@<private-ip>
	```
SSH into the application server.  

6. SSH into the "Jenkins" server and run `ssh-keygen`. Copy the public key that was created and append it into `~/.ssh/authorized_key` to allow SSH to the Web Server. 

	IMPORTANT: Test the connection by SSH'ing into the 'Web_Server' from the 'Jenkins' server.  This will also add the web server instance to the "list of known hosts"

Question: What does it mean to be a known host?  

Answer: If the client (Jenkins) previously connected to the host (Web server), then it will be added into the knownhost list as a know host. For the later connections, it will check the public key with the stored public key in the authorized_keys.   


### Scripts

7. Create scripts.  2 scripts are required for this Workload and outlined below:

a) a "start_app.sh" script that will run on the application server that will set up the server so that has all of the dependencies that the application needs, clone the GH repository, install the application dependencies from the requirements.txt file as well as [gunicorn, pymysql, cryptography], set ENVIRONMENTAL Variables, flask commands, and finally the gunicorn command that will serve the application IN THE BACKGROUND

b) a "setup.sh" script that will run in the "Web_Server" that will SSH into the "Application_Server" to run the "start_app.sh" script.
8. `setup.sh` is a script automated the process of SSH into application server and runing the application by executing the start_app.sh.  So it has the commands
  
   ```
   ssh /path/to/pemkey hostname@<private ip address> source /path/to/start_app.sh
   ```
9. `start_app.sh` is a script that automates the creation of the virtual environment, installs dependencies, pulls source code from GitHub, sets environment variables, and runs the application.



	Question: What is the difference between running scripts with the source command and running the scripts either by changing the permissions or by using the 'bash' interpreter?  

	Answer: `source` modifies the variables, settings, and other components in the script globally, persisting in the shell. In contrast, `./` as well as `bash` modifies the variables locally in the newly created shell.

	`source` is more commonly used for setting environment variables. The purpose of these two commands is to initialize or set the environment, so we can use `source` to run the scripts.

	Using the `source` and `bash` commands does not require changing the file's permissions; only read permission is needed. This approach is safer in most cases to avoid unauthorized execution than using `./`.


### Peering VPCs

10. As the default VPC need to communicate with costum VPC, so we should build the connection by configuring Prring Connection which allow them communicating using private IP address. Then modify the route tables. The custum VPC route tables should add the CIDR of the default VPC. Also for the default VPC.

The final resource for the custom VPC is
<div align="center">
	<img width="1476" alt="image" src="https://github.com/user-attachments/assets/958add8c-eccb-4615-894e-437722dcffaf">

</div>

### Jenkinsfile 
11. Create a Jenkinsfile that will 'Build' the application, 'Test' the application by running a pytest (you can re-use the test from WL3 or challenge yourself to create a new one), run the OWASP dependency checker, and then "Deploy" the application by SSH'ing into the "Web_Server" to run "setup.sh" (which would then run "start_app.sh").

IMPORTANT/QUESTION/HINT: How do you get the scripts onto their respective servers if they are saved in the GitHub Repo?  Do you SECURE COPY the file from one server to the next in the pipeline? Do you C-opy URL the file first as a setup? How much of this process is manual vs. automated?  

Saving scripts on GitHub is beneficial because whenever a script gets updated, the Jenkins pipeline retrieves the most up-to-date version to implement CI/CD. To place each script on its corresponding server, we can use curl to copy the file to the specified location and execute it.

The automation implemented using Jenkins retrieves the latest setup.sh and start_app.sh, placing them on the web server and application server, respectively. The setup.sh is run automatically by including the command in the deploy stage, which SSHs into the application server to start the application. So far, the automated deployment has been successfully achieved.

Question 2: In WL3, a method of "keeping the process alive" after a Jenkins stage completed was necessary.  Is it in this Workload? Why or why not?

In workload 3, to "keep process alive", we used the process manager `systemctl` to configure Jenkins as a system service. If the system crashed, this system service can be reboot. In this workload, since we have the script automate the start of the applicaiton, system service to keep process alive is not necessary. 

12. Create a MultiBranch Pipeline and run the build. IMPORTANT: Make sure the name of the pipeline is: "workload_4".  Check to see if the application can be accessed from the public IP address of the "Web_Server".
<img width="1250" alt="image" src="https://github.com/user-attachments/assets/553cabac-b735-4cf4-8cf1-846560d68467">

13. If all is well, create an EC2 t3.micro called "Monitoring" with Prometheus and Grafana and configure it so that it can collect metrics on the application server.
    Prometheus
    	<div align="center">
	<img width="611" alt="image" src="https://github.com/user-attachments/assets/b14ef3d0-8e3f-4c9c-9742-cbc1541517d5">
	    
    	</div>
    Grafana
	<div align="center">
		<img width="1589" alt="image" src="https://github.com/user-attachments/assets/fdaad756-e078-4281-9a9d-395cca65fa5b">

	</div>
15. Application Run
	<div>
		<img width="1589" alt="image" src="https://github.com/user-attachments/assets/415de65a-6702-4ce1-ba7a-991d988de1b1">

	</div> 
## ISSUES/TROUBLESHOOTING   


1. The pytest module not found error, can be sovled by add dependencies into the requirements.txt file.
 <div align="center">
	 <img width="681" alt="image" src="https://github.com/user-attachments/assets/3f18ae32-84d6-472a-8439-3ba8ac9906c3">
</div>
2. Cannot connect to 5000 issue. This issue cause by run the application locally before, so the port is taken. It was solved by kill the Gunicorn run on port 5000.   
<div align="center">
	<img width="720" alt="image" src="https://github.com/user-attachments/assets/3d5eb0d7-af3a-483e-9d3f-61ab0ab94f30">

</div>
3. Deploy can not complete issue. This is solved by run the applicaiton in the background, then the deplu stage can complete.

<div align="center">
	<img width="649" alt="image" src="https://github.com/user-attachments/assets/3d29b35c-4dd0-4928-a389-cb0f5aae82cb">

</div>

## OPTIMIZATION

### Questions  
1. What are the advantages of separating the deployment environment from the production environment?  

   Isolating the production environment and the deployment environment allows for better control of each environment, solving problems individually instead of causing errors in different parts of the pipeline. This improves collaboration and efficiency, resulting in a more highly available application.

2. Does the infrastructure in this workload address these concerns?

	In this workload, the production and deployment environments are not isolated. The application running now still relies on one environment setting.

 
4. Could the infrastructure created in this workload be considered that of a "good system"?  Why or why not?  How would you optimize this infrastructure to address these issues?

 	This infrastructure is created to simulate the complete process of CI/CD, considering automation and security issues. However, it can be improved by isolating environments for each stage to enhance the infrastructure's high availability. This can also be improved from a resilience perspective because we currently only have one VPC holding the resources. The application server has full control of the application, which can be improved.

##  CONCLUSION

From this workload, I have practiced how to consider the process from an automation perspective, gaining a better understanding of CI/CD and each stage of the pipeline. I practiced using Jenkins and writing Jenkinsfiles to manipulate each stage of the pipeline. I also practiced how to build a custom VPC along with subnets, associate route tables, and establish VPC Peering Connections. For the next workload, considering automation, scaling, and availability perspectives will be helpful. 


## References

* <a href="https://www.geeksforgeeks.org/source-command-in-linux-with-examples/" target="_blank">Enable auto-assign public IPv4 address in AWS</a>
* <a href="https://stackoverflow.com/questions/71904283/enable-auto-assign-public-ipv4-address-in-aws" target="_blank">source Command in Linux with Examples</a>
* <a href="https://www.qovery.com/blog/everything-you-need-to-know-about-deployment-environments/" target="_blank">Everything You Need to Know About Deployment Environments in 2023 </a>
* No Code Generated or answer was by ChatGPT


