Got it! If you'd like the Azure CLI to output **subscription IDs quoted and commented with their names**, like this:

```plaintext
"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",  //Subscription Name 1
"yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy",  //Subscription Name 2
```

Use this command:

```bash
az account list --query "[].join('', ['\"', id, '\"', ',  //', name])" -o tsv
```

### ✅ Sample Output:

```
"12345678-aaaa-bbbb-cccc-1234567890ab",  //Production
"87654321-bbbb-cccc-dddd-0987654321ba",  //Development
```

Let me know if you want this saved to a file or filtered by tenant.
