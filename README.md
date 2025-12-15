# requirements:

- gh
- jq
- Change this to your organization name or github username: `export ORG=""`

# run:

```bash

./scanner.sh

Usage:
  ./scanner.sh download              Download SBOMs for all repos
  ./scanner.sh search <package>      Search package in downloaded SBOMs

➜ ./scanner.sh download
[+] Processing Cimihan123/sbom-dependency-scanner
[+] Processing Cimihan123/files

➜ ./scanner.sh search next
Searching for package: next

Repo: Cimihan123/decrypter-hub-app
  Package: next
  Version: 15.4.10

Repo: Cimihan123/files
  Package: next
  Version: 14.1.0

```

