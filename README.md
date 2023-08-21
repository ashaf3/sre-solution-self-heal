# SRE Self-Heal Solution

## Issue:

In the modern, fast-paced world of software delivery, uptime and reliability are of paramount importance. As part of the Site Reliability Engineering (SRE) team, the aim is to ensure that services remain available 24x7. However, issues are inevitable, and sometimes they arise from the most unexpected quarters. One such issue is a DB outage which could lead to application downtime or degraded performance.

## Example:

Imagine a scenario where a monitoring tool like Datadog sends an alert indicating a DB outage. Traditionally, an engineer would have to manually intervene, diagnose the issue, and apply remediation steps. This could be time-consuming, error-prone, and may not guarantee the fastest recovery time.

## Remediation Steps:

Upon receiving an alert for a DB outage, the following manual steps would typically be taken:

1. Log in to AWS ECS.
2. Stop the affected ECS service.
3. Update the ECS task definition, perhaps to roll back to a stable version or to adjust certain parameters.
4. Clear certain items from a DynamoDB table that are associated with the DB outage.
5. Start the ECS service with the updated task definition.

The above steps involve multiple AWS services and manual interventions which could extend the downtime.

## Solution:

To eliminate the need for manual intervention and achieve faster recovery times, we aim to automate the remediation steps. Automation can ensure that the system self-heals without human intervention, reducing downtime and human error.

### Approach:

1. **Environment Setup**:
   - Use Terraform to provision the necessary AWS infrastructure. This includes setting up an ECS environment, deploying two sample services with the Fargate launch type, and creating a couple of DynamoDB tables. 
   - Manually populate the DynamoDB tables with test data.

2. **Automation Logic**:
   - Write a Python script that encapsulates the remediation steps.
   - Deploy this script as an AWS Lambda function.
   - Use a Datadog webhook to trigger the remediation process. When an alert is received, the webhook sends a message to an AWS SNS topic.
   - AWS EventBridge listens for messages on the SNS topic and invokes the Lambda function.
   - The Lambda function executes the remediation steps.
   - Logging is integrated into the Python script to track its execution and any potential errors. These logs are sent to AWS CloudWatch for monitoring and diagnostics.

3. **Deployment**:
   - Start by deploying the infrastructure using the `infra-provision.tf` Terraform script.
   - Next, package the Python script into a ZIP file and deploy the Lambda function using the `lambda-deploy.tf` Terraform script.
   - Test the entire setup by manually invoking the Lambda function using the AWS CLI.

4. **Future Implementation**:
   - Extend the Terraform scripts to automatically set up the Datadog webhook, the SNS topic, and EventBridge.
   - Further refine the Lambda function to handle different types of alerts and remediation scenarios.
   - Monitor the solution in a staging environment before promoting to production.

## Conclusion:

Achieving a self-healing system is an essential goal for SRE teams. While the initial setup might seem complex, the long-term benefits in terms of reduced downtime, fewer manual interventions, and faster recovery times are invaluable. The approach outlined here provides a blueprint for creating such a self-healing system. As always, it's crucial to test thoroughly in a controlled environment before deploying to production. Future enhancements could include refining the remediation logic, integrating more monitoring tools, and expanding the range of self-healable issues.
