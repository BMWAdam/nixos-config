# nixos-config
My NixOS Configuration

### To re-cypher config file
```bash
sops --encrypt --output secrets/encrypted.yaml .config/sops/system-config.yaml
```

### To enroll a fingerprint
```bash
sudo fprintd-enroll -f right-index-finger $USER
```
