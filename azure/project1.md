Thanks for pointing that out — you're right! Azure CLI’s `--query` parameter uses **JMESPath**, which doesn’t support the kind of string concatenation you're aiming for directly within the query. To get the desired output format, we’ll need to handle formatting outside the query using a script (Bash or PowerShell).

---

### ✅ If you’re using **Bash** (Linux/macOS or WSL):

```bash
az account list --query "[].{id:id, name:name}" -o tsv | while IFS=$'\t' read -r id name; do
  echo "\"$id\",  //$name"
done
```

---

### ✅ If you’re using **PowerShell** (Windows/macOS/Linux):

```powershell
az account list --query "[].{id:id, name:name}" -o tsv | ForEach-Object {
    $parts = $_ -split "`t"
    $id = $parts[0]
    $name = $parts[1]
    Write-Output "`"$id`",  //$name"
}
```

---

### 📌 Example Output:

```
"11111111-2222-3333-4444-555555555555",  //Dev Subscription
"66666666-7777-8888-9999-000000000000",  //Prod Subscription
```

Let me know which shell you're using if you'd like it more tailored!
