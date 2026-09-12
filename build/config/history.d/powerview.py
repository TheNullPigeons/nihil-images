powerview "$DOMAIN/$USER:$PASSWORD"@"$TARGET" --use-ldap
powerview "$DOMAIN/$USER:$PASSWORD"@"$TARGET" --use-ldaps
powerview "$DOMAIN/$USER@$TARGET" -H "$NT_HASH"
