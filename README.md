If you landed here directly and want to know how to setup Jenkins master-slave architecture, please visit this post related to Setting-up the Jenkins Master-Slave Architecture.

The source code that we are using here is also a continuation of the code that was written in this GitHub Packer-Terraform-Jenkins repository.

Creating Jenkinsfile
We will create some Jenkinsfile to execute a job from our Jenkins master.

Here I will create two Jenkinsfile ideally, it is expected that your Jenkinsfile is present in source code repo but it can be passed directly in the job as well.

There are 2 ways of writing Jenkinsfile - Scripted and Declarative. You can find numerous points online giving their difference. We will be creating both of them to do a build so that we can get a hang of both of them.

Jenkinsfile for Angular App (Scripted)
As mentioned before we will be highlighting both formats of writing the Jenkinsfile. For the Angular app, we will be writing a scripted one but can be easily written in declarative format too.

We will be running this inside a docker container. Thus, the tests are also going to get executed in a headless manner.

Here is the Jenkinsfile for reference.

Here we are trying to leverage Docker volume to keep updating our source code on bare metal and use docker container for the environments.

Dissecting Node App's Jenkinsfile
We are using CleanWs() to clear the workspace.
Next is the Main build in which we define our complete build process.
We are pulling the required images.
Highlighting the steps that we will be executing.
Checkout SCM: Checking out our code from Git
We are now starting the node container inside of which we will be running npm install and npm run lint.
Get test dependency: Here we are downloading chrome.json which will be used in the next step when starting the container.
Here we test our app. Specific changes for running the test are mentioned below.
Build: Finally we build the app.
Deploy: Once CI is completed we need to start with CD. The CD itself can be a blog of itself but wanted to highlight what basic deployment would do.
Here we are using Nginx container to host our application.
If the container does not exist it will create a container and use the "dist" folder for deployment.
If Nginx container exists, then it will ask for user input to recreate a container or not.
If you select not to create, don't worry as we are using Nginx it will do a hot reload with new changes.
The angular application used here was created using the standard generate command given by the CLI itself. Although the build and install give no trouble in a bare metal some tweaks are required for running test in a container.

In karma.conf.js update browsers withChromeHeadless.

Next in protractor.conf.js update browserName with chrome and add

That's it! And We have our CI pipeline setup for Angular based application.

Jenkinsfile for .Net App (Declarative)
For a .Net application, we have to setup MSBuild and MSDeploy. In the blog post mentioned above, we have already setup MSBuild and we will shortly discuss how to setup MSDeploy.

To do the Windows deployment we have two options. Either setup MSBuild in Jenkins Global Tool Configuration or use the full path of MSBuild on the slave machine.

Passing the path is fairly simple and here we will discuss how to use global tool configuration in a Jenkinsfile.

First, get the path of MSBuild from your server. If it is not the latest version then the path is different and is available in Current directory otherwise always in <version> directory.</version>

As we are using MSBuild 2017. Our MSBuild path is:

C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin

Place this in /configureTools/ —> MSBuild

Jenkinfile 1.png
Now you have your configuration ready to be used in Jenkinsfile.

Jenkinsfile to build and test the app is given below.

As seen above the structure of Declarative syntax is almost same as that of Declarative. Depending upon which one you find easier to read you should opt the syntax.

Dissecting Dotnet App's Jenkinsfile
In this case too we are cleaning the workspace as the first step.
Checkout: This is also the same as before.
Nuget Restore: We are downloading dependent required packages for both PrimeService and PrimeService.Tests
Build: Building the Dotnet app using MSBuild tool which we had configured earlier before writing the Jenkinsfile.
UnitTest: Here we have used dotnet test although we could've used MSTest as well here just wanted to highlight how easy dotnet utility makes it. We can even use dotnet build for the build as well.
Deploy: Deploying on the IIS server. Creation of IIS we are covering below.
From the above-given examples, you get a hang of what Jenkinsfile looks like and how it can be used for creating jobs. Above file highlights basic job creation but it can be extended to everything that old-style job creation could do.

Creating IIS Server
Unlike our Angular application where we just had to get another image and we were good to go. Here we will have to Packer to create our IIS server. We will be automating the creation process and will be using it to host applications.

Here is a Powershell script for IIS for reference.

=========================================

Automation is everywhere and it is better to adopt it as soon as possible. Today, in this blog post, we are going to discuss creating the infrastructure. For this, we will be using AWS for hosting our deployment pipeline. Packer will be used to create AMI’s and Terraform will be used for creating the master/slaves. We will be discussing different ways of connecting the slaves and will also run a sample application with the pipeline.

Please remember the intent of the blog is to accumulate all the different components together, this means some of the code which should be available in development code repo is also included here. Now that we have highlighted the required tools, 10000 ft view and intent of the blog. Let’s begin.

Using Packer to Create AMI’s for Jenkins Master and Linux Slave
Hashicorp has bestowed with some of the most amazing tools for simplifying our life. Packer is one of them. Packer can be used to create custom AMI from already available AMI’s. We just need to create a JSON file and pass installation script as part of creation and it will take care of developing the AMI for us. Install packer depending upon your requirement from Packer downloads page. For simplicity purpose, we will be using Linux machine for creating Jenkins Master and Linux Slave. JSON file for both of them will be same but can be separated if needed.

Note: user-data passed from terraform will be different which will eventually differentiate their usage.

We are using Amazon Linux 2 - JSON file for the same.

As you can see the file is pretty simple. The only thing of interest here is the install_amazon.bash script. In this blog post, we will deploy a Node-based application which is running inside a docker container. Content of the bash file is as follows:

Now there are a lot of things mentioned let’s check them out. As mentioned earlier we will be discussing different ways of connecting to a slave and for one of them, we need xmlstarlet. Rest of the things are packages that we might need in one way or the other.

Update ami_users with actual user value. This can be found on AWS console Under Support and inside of it Support Center.

Validate what we have written is right or not by running packer validate amazon.json.

Once confirmed, build the packer image by running packer build amazon.json.

After completion check your AWS console and you will find a new AMI created in “My AMI’s”.

It's now time to start using terraform for creating the machines. 

Prerequisite:

1. Please make sure you create a provider.tf file.

The ‘credentials file’ will contain aws_access_key_id and aws_secret_access_key.

2.  Keep SSH keys handy for server/slave machines. Here is a nice article highlighting how to create it or else create them before hand on aws console and reference it in the code.

ssh-copy-id sammy@your_server_address
ssh-copy-id user_name@ip


