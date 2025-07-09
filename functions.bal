import ballerina/time;
import ballerina/uuid;

// In-memory token storage (in production, this would be a database)
map<TokenMetadata> tokenStorage = {};

// Function to validate customer and generate verification token
public function validateCustomerAndGenerateToken(string customerId, string phoneNumber, string accountType) returns CustomerVerificationResponse {
    // Mock validation logic
    boolean isVerified = customerId.length() >= 5 && phoneNumber.startsWith("+");
    string verificationStatus = isVerified ? "VERIFIED" : "FAILED";
    string riskLevel = accountType == "PREMIUM" ? "LOW" : "MEDIUM";
    
    // Generate verification token
    string verificationToken = uuid:createType1AsString();
    
    // Set expiration time (1 hour from now)
    time:Utc currentTime = time:utcNow();
    time:Utc expirationTime = time:utcAddSeconds(currentTime, 3600);
    string expiresAt = time:utcToString(expirationTime);
    string createdAt = time:utcToString(currentTime);

    // Store token metadata for validation
    TokenMetadata tokenMetadata = {
        token: verificationToken,
        customerId: customerId,
        phoneNumber: phoneNumber,
        accountType: accountType,
        createdAt: createdAt,
        expiresAt: expiresAt,
        isActive: isVerified
    };
    
    tokenStorage[verificationToken] = tokenMetadata;

    return {
        customerId: customerId,
        isVerified: isVerified,
        verificationStatus: verificationStatus,
        verificationToken: verificationToken,
        accountType: accountType,
        riskLevel: riskLevel,
        expiresAt: expiresAt
    };
}

// Enhanced function to validate verification token with detailed error messages
public function validateVerificationTokenWithDetails(string token) returns TokenValidationResult {
    // Check token format
    if token.length() <= 10 {
        return {
            isValid: false,
            validationStatus: "INVALID_FORMAT",
            errorCode: "TOKEN_FORMAT_ERROR",
            errorMessage: "Token format is invalid. Token must be longer than 10 characters.",
            tokenData: ()
        };
    }

    // Check if token exists in storage
    if !tokenStorage.hasKey(token) {
        return {
            isValid: false,
            validationStatus: "TOKEN_NOT_FOUND",
            errorCode: "TOKEN_NOT_EXISTS",
            errorMessage: "Verification token not found. Please request a new verification token.",
            tokenData: ()
        };
    }

    TokenMetadata tokenData = tokenStorage.get(token);

    // Check if token is active
    if !tokenData.isActive {
        return {
            isValid: false,
            validationStatus: "TOKEN_INACTIVE",
            errorCode: "TOKEN_DEACTIVATED",
            errorMessage: "Token has been deactivated due to failed verification.",
            tokenData: tokenData
        };
    }

    // Check token expiration
    time:Utc|error expirationTime = time:utcFromString(tokenData.expiresAt);
    if expirationTime is error {
        return {
            isValid: false,
            validationStatus: "EXPIRATION_PARSE_ERROR",
            errorCode: "TOKEN_EXPIRATION_ERROR",
            errorMessage: "Unable to parse token expiration time.",
            tokenData: tokenData
        };
    }

    time:Utc currentTime = time:utcNow();
    time:Seconds timeDifference = time:utcDiffSeconds(currentTime, expirationTime);
    if timeDifference > 0.0d {
        return {
            isValid: false,
            validationStatus: "TOKEN_EXPIRED",
            errorCode: "TOKEN_EXPIRED",
            errorMessage: "Verification token has expired. Please request a new verification token.",
            tokenData: tokenData
        };
    }

    // Token is valid
    return {
        isValid: true,
        validationStatus: "VALID",
        errorCode: (),
        errorMessage: (),
        tokenData: tokenData
    };
}

// Function to compare multiple verification tokens
public function compareMultipleTokens(string[] tokensToValidate, string targetPhoneNumber) returns MultiTokenComparisonResponse {
    string[] validTokens = [];
    string[] invalidTokens = [];
    TokenValidationResult[] validationResults = [];

    foreach string token in tokensToValidate {
        TokenValidationResult validationResult = validateVerificationTokenWithDetails(token);
        validationResults.push(validationResult);

        if validationResult.isValid {
            // Additional check: verify token belongs to the target phone number
            TokenMetadata? tokenData = validationResult.tokenData;
            if tokenData is TokenMetadata && tokenData.phoneNumber == targetPhoneNumber {
                validTokens.push(token);
            } else {
                invalidTokens.push(token);
                // Update validation result for phone number mismatch
                validationResult.isValid = false;
                validationResult.validationStatus = "PHONE_NUMBER_MISMATCH";
                validationResult.errorCode = "PHONE_MISMATCH";
                validationResult.errorMessage = "Token does not belong to the specified phone number.";
            }
        } else {
            invalidTokens.push(token);
        }
    }

    return {
        validTokens: validTokens,
        invalidTokens: invalidTokens,
        validationResults: validationResults,
        totalTokensChecked: tokensToValidate.length(),
        validTokenCount: validTokens.length()
    };
}

// Function to validate verification token (backward compatibility)
public function isValidVerificationToken(string token) returns boolean {
    TokenValidationResult result = validateVerificationTokenWithDetails(token);
    return result.isValid;
}

// Function to simulate SMS sending via external service
public function sendSmsViaExternalService(string phoneNumber, string message) returns SmsAlertResponse {
    // Mock SMS sending logic
    string messageId = "SM" + time:utcNow()[0].toString();
    time:Utc currentTime = time:utcNow();
    string sentAt = time:utcToString(currentTime);

    return {
        messageId: messageId,
        status: "sent",
        recipient: phoneNumber,
        sentMessage: message,
        delivered: true,
        sentAt: sentAt
    };
}

// Function to build alert message based on alert type
public function buildAlertMessage(string alertType) returns string {
    match alertType {
        "PAYMENT_DUE" => {
            return "TELECOM ALERT: Your monthly bill payment is due in 3 days. Pay now to avoid service interruption.";
        }
        "SERVICE_ACTIVATION" => {
            return "TELECOM NOTIFICATION: Your new service plan has been activated successfully. Enjoy your upgraded features!";
        }
        "USAGE_ALERT" => {
            return "TELECOM WARNING: You have used 90% of your monthly data allowance. Consider upgrading your plan.";
        }
        "SECURITY_ALERT" => {
            return "TELECOM SECURITY: Unusual activity detected on your account. Please contact customer service if this wasn't you.";
        }
        _ => {
            return "TELECOM NOTIFICATION: Important update regarding your telecom account.";
        }
    }
}

// Function to get current timestamp
public function getCurrentTimestamp() returns string {
    time:Utc currentTime = time:utcNow();
    return time:utcToString(currentTime);
}

// Function to deactivate a token
public function deactivateToken(string token) returns boolean {
    if tokenStorage.hasKey(token) {
        TokenMetadata tokenData = tokenStorage.get(token);
        tokenData.isActive = false;
        tokenStorage[token] = tokenData;
        return true;
    }
    return false;
}

// Function to get all active tokens for a phone number
public function getActiveTokensForPhoneNumber(string phoneNumber) returns string[] {
    string[] activeTokens = [];
    
    string[] tokenKeys = tokenStorage.keys();
    foreach string token in tokenKeys {
        TokenMetadata tokenData = tokenStorage.get(token);
        if tokenData.phoneNumber == phoneNumber && tokenData.isActive {
            // Check if token is not expired
            time:Utc|error expirationTime = time:utcFromString(tokenData.expiresAt);
            if expirationTime is time:Utc {
                time:Utc currentTime = time:utcNow();
                time:Seconds timeDifference = time:utcDiffSeconds(currentTime, expirationTime);
                if timeDifference <= 0.0d {
                    activeTokens.push(token);
                }
            }
        }
    }
    
    return activeTokens;
}