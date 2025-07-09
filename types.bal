// Customer verification request
public type CustomerVerificationRequest record {
    string customerId;
    string phoneNumber;
    string accountType;
};

// Customer verification response with token
public type CustomerVerificationResponse record {
    string customerId;
    boolean isVerified;
    string verificationStatus;
    string verificationToken;
    string accountType;
    string riskLevel;
    string expiresAt;
};

// SMS alert request requiring verification token
public type SmsAlertRequest record {
    string verificationToken;
    string phoneNumber;
    string alertType;
    string message;
};

// SMS alert response
public type SmsAlertResponse record {
    string messageId;
    string status;
    string recipient;
    string sentMessage;
    boolean delivered;
    string sentAt;
};

// Error response
public type ErrorResponse record {
    string message;
    string code;
    string timestamp;
    string? details;
};

// Token metadata for storage and validation
public type TokenMetadata record {
    string token;
    string customerId;
    string phoneNumber;
    string accountType;
    string createdAt;
    string expiresAt;
    boolean isActive;
};

// Token validation result
public type TokenValidationResult record {
    boolean isValid;
    string validationStatus;
    string? errorCode;
    string? errorMessage;
    TokenMetadata? tokenData;
};

// Multiple token comparison request
public type MultiTokenComparisonRequest record {
    string[] tokensToValidate;
    string targetPhoneNumber;
};

// Multiple token comparison response
public type MultiTokenComparisonResponse record {
    string[] validTokens;
    string[] invalidTokens;
    TokenValidationResult[] validationResults;
    int totalTokensChecked;
    int validTokenCount;
};