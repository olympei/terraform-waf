# Enterprise Zero-Trust WAF with Database Client Support

This example demonstrates an enterprise-grade zero-trust WAF configuration that blocks all traffic by default and explicitly allows legitimate HTTP/HTTPS traffic, including support for database clients.

## 🛡️ Zero-Trust Security Model

- **Default Action**: BLOCK (zero-trust principle)
- **Explicit Allow Rules**: Only trusted traffic patterns are allowed
- **Geographic Restrictions**: Only trusted countries are permitted
- **Multi-Layer Validation**: Multiple security checks for each request

## 🔧 Database Client Support

### Feature Overview
The WAF includes a configurable rule to allow HTTP traffic containing "dbclient" in specified headers. This is useful for:
- Database administration tools
- Custom database clients
- Automated database scripts
- API clients that need database access

### Configuration Variables

```hcl
variable "enable_dbclient_access" {
  description = "Enable access for database clients with 'dbclient' header"
  type        = bool
  default     = true
}

variable "dbclient_headers" {
  description = "List of headers to check for 'dbclient' value (case-insensitive)"
  type        = list(string)
  default     = ["x-client-type", "user-agent", "x-application", "authorization"]
}
```

### Usage Examples

#### 1. Using x-client-type Header
```bash
curl -H "x-client-type: dbclient" https://api.example.com/data
```

#### 2. Using User-Agent Header
```bash
curl -H "user-agent: MyApp/1.0 dbclient" https://api.example.com/query
```

#### 3. Using x-application Header
```bash
curl -H "x-application: dbclient-v2.1" https://api.example.com/connect
```

#### 4. Using Authorization Header
```bash
curl -H "authorization: Bearer token-dbclient-xyz" https://api.example.com/auth
```

## 🚀 Deployment

### Basic Deployment
```hcl
module "enterprise_zero_trust_waf" {
  source = "./examples/enterprise_zero_trust_waf"
  
  name         = "my-zero-trust-waf"
  alb_arn_list = ["arn:aws:elasticloadbalancing:..."]
  
  # Database client support (enabled by default)
  enable_dbclient_access = true
  dbclient_headers = ["x-client-type", "user-agent", "x-application"]
}
```

### Disable Database Client Access
```hcl
module "enterprise_zero_trust_waf" {
  source = "./examples/enterprise_zero_trust_waf"
  
  name         = "my-zero-trust-waf"
  alb_arn_list = ["arn:aws:elasticloadbalancing:..."]
  
  # Disable database client support
  enable_dbclient_access = false
}
```

### Custom Header Configuration
```hcl
module "enterprise_zero_trust_waf" {
  source = "./examples/enterprise_zero_trust_waf"
  
  name         = "my-zero-trust-waf"
  alb_arn_list = ["arn:aws:elasticloadbalancing:..."]
  
  # Custom headers for dbclient detection
  dbclient_headers = ["x-db-client", "x-custom-client", "user-agent"]
}
```

## 🧪 Testing

Use the provided test script to verify the dbclient functionality:

```bash
# Make script executable
chmod +x test_dbclient.sh

# Run tests against your ALB endpoint
./test_dbclient.sh https://your-alb-endpoint.com/api/test
```

The test script will:
1. Test requests without dbclient header (should be blocked)
2. Test requests with dbclient in various headers (should be allowed)
3. Test different HTTP methods
4. Provide troubleshooting guidance

## 📊 Monitoring

### CloudWatch Metrics
- `allow_dbclient_traffic` - Successful dbclient requests
- `allow_trusted_countries` - Geographic allow matches
- `allow_legitimate_user_agents` - Browser traffic allowed
- Default block metrics for denied requests

### Log Analysis
Enable WAF logging to analyze traffic patterns:
```hcl
enable_logging = true
create_log_group = true
log_group_retention_days = 365
```

## 🔒 Security Considerations

### Multi-Layer Validation
The dbclient rule requires BOTH:
1. **Header containing "dbclient"** (case-insensitive)
2. **Request from trusted country** (geographic validation)

### Header Security
- Headers are checked case-insensitively
- Multiple headers can be configured for flexibility
- Headers are validated using AWS WAF's built-in text transformations

### Geographic Restrictions
Even with valid dbclient headers, requests must originate from trusted countries:
- Default: US, CA, GB, DE, FR, AU, JP, NL, SE, CH
- Configurable via `trusted_countries` variable

## 🎯 Rule Priority

The dbclient rule has priority 19, placing it:
- **After** geographic validation (priority 10)
- **After** standard HTTP methods (priorities 15-18)
- **Before** user-agent validation (priority 20)

## 📋 Allowed Traffic Summary

When `enable_dbclient_access = true`, the WAF allows:

1. **Geographic**: Trusted countries only
2. **HTTP Methods**: GET, POST, PUT, PATCH, OPTIONS
3. **Database Clients**: Headers containing "dbclient"
4. **Browsers**: Mozilla, Chrome, Safari, Edge, Firefox
5. **Static Resources**: CSS, JS, images, fonts
6. **Special Paths**: /health, /robots.txt, /sitemap.xml, /favicon.ico
7. **APIs**: REST APIs with proper content-type

## 🚨 Important Notes

- **Zero-Trust**: Default action is BLOCK - test thoroughly!
- **Geographic Restrictions**: Only trusted countries are allowed
- **Header Validation**: Case-insensitive matching for "dbclient"
- **Monitoring Required**: Enable CloudWatch logging for visibility
- **Testing Essential**: Use the test script before production deployment

## 📞 Troubleshooting

### Common Issues

1. **Requests Blocked Despite dbclient Header**
   - Check if request originates from trusted country
   - Verify header name matches configured list
   - Ensure "dbclient" text is present in header value

2. **All Requests Blocked**
   - Verify ALB is associated with WAF
   - Check CloudWatch logs for rule matches
   - Confirm geographic location is in trusted countries

3. **Unexpected Allows**
   - Review all allow rules in priority order
   - Check if request matches other allow patterns
   - Monitor CloudWatch metrics for rule matches

### Debug Commands

```bash
# Check WAF association
aws wafv2 list-resources-for-web-acl --web-acl-arn <waf-arn>

# View CloudWatch logs
aws logs filter-log-events --log-group-name aws-waf-logs-<name>

# Test from different locations
curl -H "x-client-type: dbclient" -v https://your-endpoint.com
```

This configuration provides enterprise-grade security while maintaining flexibility for legitimate database client access.