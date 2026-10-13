#!/usr/bin/env zsh
set -eu
source "${0:A:h}/../build/config/aliases.d/kerbrute"
test_dir=$(mktemp -d)
trap 'rm -rf -- "$test_dir"' EXIT
cat > "$test_dir/kerbrute.log" <<'EOF'
2026/09/28 18:17:22 >  [+] VALID USERNAME:	 guest@SOMBRA.COM
2026/09/28 18:17:23 >  [+] VALID USERNAME:	 administrator@SOMBRA.COM
2026/09/28 18:17:32 >  [+] VALID USERNAME:	 Guest@SOMBRA.COM
2026/09/28 18:17:45 >  [+] VALID USERNAME:	 dstone@SOMBRA.COM
2026/09/28 18:18:08 >  [+] VALID USERNAME:	 GUEST@SOMBRA.COM
2026/09/28 18:18:59 >  [-] INVALID USERNAME:	 unknown@SOMBRA.COM
EOF
kerbrute_users_dump "$test_dir/kerbrute.log" "$test_dir/users.txt"
diff -u <(print -l guest administrator dstone) "$test_dir/users.txt"
! kerbrute_users_dump "$test_dir/kerbrute.log" "$test_dir/kerbrute.log" 2>/dev/null
