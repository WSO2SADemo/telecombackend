import ballerina/http;

// Mock HTTP client for external services (simulating Twilio)
final http:Client mockTwilioClient = check new ("https://api.twilio.com");