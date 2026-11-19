# Token de git desde Secret Manager: git lo pide al helper en cada clone/pull, así
# no queda en la URL, la metadata, el state ni en .git/config.
echo "Configurando credenciales de git desde Secret Manager..."
cat > /usr/local/bin/git-credential-secret-manager <<'HELPER_EOF'
#!/bin/bash
# git llama "<helper> get" y espera username/password por stdout.
[ "$1" = get ] || exit 0
export PATH="$PATH:/snap/bin:/usr/lib/google-cloud-sdk/bin"
token=$(gcloud secrets versions access latest --secret="${git_token_secret_id}") || exit 1
printf 'username=x-access-token\npassword=%s\n' "$token"
HELPER_EOF
chmod 755 /usr/local/bin/git-credential-secret-manager
git config --system --replace-all credential.https://github.com.helper secret-manager
