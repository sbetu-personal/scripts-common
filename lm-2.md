Here's the modified Lambda code that accepts the Apigee URL as input via the event object, along with instructions:

---

### **Updated Lambda Code (Python 3.12)**
```python
import http.client
import ssl
from urllib.parse import urlparse

def lambda_handler(event, context):
    # Get URL from event input
    apigee_url = event.get('apigee_url')
    
    if not apigee_url:
        return {
            "statusCode": 400,
            "body": "Missing apigee_url in event input"
        }

    try:
        # Parse URL components
        parsed_url = urlparse(apigee_url)
        host = parsed_url.hostname
        path = parsed_url.path or "/"

        # Create HTTPS connection
        context = ssl._create_unverified_context()  # For testing only!
        conn = http.client.HTTPSConnection(host, context=context)
        
        conn.request("GET", path)
        response = conn.getresponse()
        
        return {
            "statusCode": response.status,
            "body": f"Connected successfully to {host}",
            "response_status": response.status,
            "response_reason": response.reason
        }
        
    except Exception as e:
        return {
            "statusCode": 500,
            "body": f"Connection failed: {str(e)}",
            "host_attempted": host
        }
```

---

### **Step-by-Step Test Configuration**

1. **Create Test Event in AWS Console:**
   - In Lambda console, go to **Test** tab
   - Create new event template (JSON format):
   ```json
   {
     "apigee_url": "https://api.qa.xxxx.com/your-path"
   }
   ```
   - Name: `ApigeeTestEvent`

2. **Execution Steps:**
   - Select the `ApigeeTestEvent` from dropdown
   - Click **Test**
   - Check results:
     - Successful connection: 200 status
     - Failure: Error details in response

---

### **Key Improvements**
1. **URL Parsing:**
   - Handles full URLs (with paths)
   - Extracts hostname automatically
   - Example inputs accepted:
     - `https://api.qa.xxxx.com`
     - `https://api.qa.xxxx.com/v1/users`

2. **Error Handling:**
   - Checks for missing URL in input
   - Captures hostname in error responses
   - Returns HTTP status codes for debugging

---

### **Security Notes**
1. **SSL Verification:**
   - Current code skips cert verification (`create_unverified_context`)
   - For production: Remove this and use valid certificates
   ```python
   # For production:
   context = ssl.create_default_context()
   ```

2. **Input Validation:**
   - Consider adding allow-list validation for URLs in production
   - Add regex pattern check for your domain

---

### **Troubleshooting Inputs**
If you get connection errors:
1. Test with different URL formats:
   - Without path: `{"apigee_url": "https://api.qa.xxxx.com"}`
   - With path: `{"apigee_url": "https://api.qa.xxxx.com/healthcheck"}`
2. Check CloudWatch logs for:
   - Actual hostname being resolved
   - Full exception stack traces

---

This version gives you flexibility to test different endpoints without modifying code. Let me know if you need help creating specific test scenarios!
