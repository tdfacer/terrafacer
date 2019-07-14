output "dynamo_table_arn" {
  value       = "${aws_dynamodb_table.table.arn}"
  description = "The ARN of the DynamoDB Table."
}
