import ballerina/http;
import ballerina/log;

// Service 1: Customer Verification Service (Port 8080)
service /verification on new http:Listener(8086) {

    function init() returns error? {
        log:printInfo("Verification Service initialised !");
    }
    
    resource function post customer(CustomerVerificationRequest request) returns CustomerVerificationResponse|ErrorResponse {
        log:printInfo("Processing customer verification request");
        
        string customerId = request.customerId;
        string phoneNumber = request.phoneNumber;
        string accountType = request.accountType;
        
        // Validate customer and generate verification token
        CustomerVerificationResponse verificationResult = validateCustomerAndGenerateToken(customerId, phoneNumber, accountType);
        
        log:printInfo("Customer verification completed with token generation");
        return verificationResult;
    }
    
    // New endpoint to compare multiple tokens
    resource function post tokens/compare(MultiTokenComparisonRequest request) returns MultiTokenComparisonResponse|ErrorResponse {
        log:printInfo("Processing multiple token comparison request");
        
        string[] tokensToValidate = request.tokensToValidate;
        string targetPhoneNumber = request.targetPhoneNumber;
        
        if tokensToValidate.length() == 0 {
            log:printError("No tokens provided for comparison");
            return <ErrorResponse>{
                message: "No tokens provided for validation",
                code: "NO_TOKENS_PROVIDED",
                timestamp: getCurrentTimestamp(),
                details: "At least one token must be provided for comparison"
            };
        }
        
        MultiTokenComparisonResponse comparisonResult = compareMultipleTokens(tokensToValidate, targetPhoneNumber);
        
        log:printInfo("Multiple token comparison completed");
        return comparisonResult;
    }
    
    resource function get health() returns map<string> {
        return {
            "service": "Customer Verification Service",
            "status": "healthy",
            "port": "8080"
        };
    }
}

// Service 2: SMS Alert Service (Port 8081) - Requires verification token from Service 1
service /sms on new http:Listener(8085) {

    function init() returns error? {
        log:printInfo("SMS Service initialised !");
    }    
    resource function post alert(SmsAlertRequest request) returns SmsAlertResponse|ErrorResponse {
        log:printInfo("Processing SMS alert request");
        
        string verificationToken = request.verificationToken;
        
        // Validate the verification token with detailed error messages
        TokenValidationResult validationResult = validateVerificationTokenWithDetails(verificationToken);
        
        if !validationResult.isValid {
            string? errorCode = validationResult.errorCode;
            string? errorMessage = validationResult.errorMessage;
            
            log:printError("Token validation failed: " + (errorMessage ?: "Unknown error"));
            return <ErrorResponse>{
                message: errorMessage ?: "Token validation failed",
                code: errorCode ?: "VALIDATION_ERROR",
                timestamp: getCurrentTimestamp(),
                details: "Validation status: " + validationResult.validationStatus
            };
        }
        
        // Additional validation: check if token phone number matches request phone number
        TokenMetadata? tokenData = validationResult.tokenData;
        if tokenData is TokenMetadata && tokenData.phoneNumber != request.phoneNumber {
            log:printError("Phone number mismatch in token validation");
            return <ErrorResponse>{
                message: "Token does not belong to the specified phone number",
                code: "PHONE_NUMBER_MISMATCH",
                timestamp: getCurrentTimestamp(),
                details: "Token is valid but associated with a different phone number"
            };
        }
        
        // Build appropriate alert message
        string alertMessage = buildAlertMessage(request.alertType);
        
        // Send SMS via external service
        SmsAlertResponse smsResult = sendSmsViaExternalService(request.phoneNumber, alertMessage);
        
        log:printInfo("SMS alert sent successfully");
        return smsResult;
    }
    
    // New endpoint to validate multiple tokens for SMS sending
    resource function post alert/batch(MultiTokenComparisonRequest request) returns MultiTokenComparisonResponse|ErrorResponse {
        log:printInfo("Processing batch token validation for SMS alerts");
        
        string[] tokensToValidate = request.tokensToValidate;
        string targetPhoneNumber = request.targetPhoneNumber;
        
        if tokensToValidate.length() == 0 {
            log:printError("No tokens provided for batch validation");
            return <ErrorResponse>{
                message: "No tokens provided for batch validation",
                code: "NO_TOKENS_PROVIDED",
                timestamp: getCurrentTimestamp(),
                details: "At least one token must be provided for batch validation"
            };
        }
        
        MultiTokenComparisonResponse comparisonResult = compareMultipleTokens(tokensToValidate, targetPhoneNumber);
        
        log:printInfo("Batch token validation completed");
        return comparisonResult;
    }
    
    resource function get health() returns map<string> {
        return {
            "service": "SMS Alert Service",
            "status": "healthy",
            "port": "8081"
        };
    }
}