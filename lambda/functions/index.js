import { SNSClient, PublishCommand } from '@aws-sdk/client-sns';

const snsClient = new SNSClient({ region: process.env.REGION });

// Lambda handler to process message from SQS queue and then publish it to topic on SNS
export const handler = async event => {
  console.log('SQS EVENT:', event);

  const batchItemFailures = [];
  if (event.Records.length == 0) {
    console.log('Empty SQS Event received');
    return { batchItemFailures };
  }

  // Extract Records array from event object. This array contains one or more SQS messages.
  const { Records } = event;

  // Process each SQS message.
  for (const record of Records) {
    const itemIdentifier = record.messageId;
    console.log(`Processing message Id: ${itemIdentifier}`);

    // Get SQS message body
    const body = JSON.parse(record.body);
    console.log('Message body:', body);

    // Publish Message to Topic on Amazon SNS
    try {
      const snsMessage = {
        Message: body.message,
        TopicArn: process.env.SNS_TOPIC_ARN
      };
      const snsResponse = await snsClient.send(new PublishCommand(snsMessage));
      console.log(`Message ${itemIdentifier} sent to SNS: ${snsResponse.MessageId}`);

      return {
        statusCode: 200
      };
    } catch (error) {
      console.error(`Error while sending message ${itemIdentifier} to SNS: ${error}`);
      batchItemFailures.push({ itemIdentifier });
      return { batchItemFailures };
    }
  }
};
