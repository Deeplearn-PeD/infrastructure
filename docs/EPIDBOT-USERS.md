# EpidBot User Management

This guide explains how to manage EpidBot users on the production environment.

## Quick Reference

| Command | Description |
|---------|-------------|
| `./scripts/epidbot-users.sh list` | List all users |
| `./scripts/epidbot-users.sh create <username> <email>` | Create new user (interactive) |
| `./scripts/epidbot-users.sh create-with-password <username> <password> <email>` | Create user (non-interactive) |
| `./scripts/epidbot-users.sh passwd <username>` | Change user password |
| `./scripts/epidbot-users.sh delete <username>` | Delete a user |
| `./scripts/epidbot-users.sh show-credentials` | Show default admin credentials |

## Commands

### List all users

```bash
./scripts/epidbot-users.sh list
```

Output:
```
=== User List ===

ID    Username             Email                          Created              Last Login          
-----------------------------------------------------------------------------------------------
1     admin                admin@example.com              2026-03-10           2026-03-10          
2     researcher           researcher@institute.org       2026-03-11           Never               

Total: 2 user(s)
```

### Create new user (interactive)

```bash
./scripts/epidbot-users.sh create researcher researcher@institute.org
```

You will be prompted for username,password
confirm password
email
```

### Create new user (non-interactive)

```bash
./scripts/epidbot-users.sh create-with-password researcher securepass123 researcher@institute.org
```

### Change password

```bash
./scripts/epidbot-users.sh passwd admin
```

### Delete user

```bash
./scripts/epidbot-users.sh delete researcher
```

### Show default admin credentials

```bash
./scripts/epidbot-users.sh show-credentials
```

## Configuration

### Required Variables

Add these to your `terraform.tfvars`:

```hcl
epidbot_admin_user      = "admin"
epidbot_admin_password  = "your-secure-password-here"
epidbot_admin_email     = "admin@yourdomain.com"
```

### Generate a secure password

```bash
openssl rand -base64 24
```

### Ansible Variables

The variables are automatically passed to the `epidbot.env.j2` template.

## Initial Setup

1. **Deploy infrastructure** (or update if already deployed):

   ```bash
   ./scripts/deploy-services.sh epidbot
   ```

2. **First login**: Use the credentials stored in `/data/.admin_credentials`

3. **Change default password immediately**:

   ```bash
   ./scripts/epidbot-users.sh passwd admin
   ```

## Security Best Practices

1. **Change default admin password** immediately after first deployment
2. **Use strong passwords** (minimum 8 characters)
3. **Create separate users** for each person who needs access
4. **Regularly review user list** and remove unused accounts
5. **Keep credentials secure** - never share passwords

## Troubleshooting

### Cannot login

1. Check if container is running:
   ```bash
   docker ps | grep epidbot
   ```

2. List existing users:
   ```bash
   ./scripts/epidbot-users.sh list
   ```

3. Reset admin password:
   ```bash
   ./scripts/epidbot-users.sh passwd admin
   ```

### Container not running

```bash
# Start container
cd /opt/kwar-ai/epidbot && docker-compose up -d

# Check logs
docker-compose logs epidbot
```

## Integration with Existing Infrastructure

- User database is stored in `/data/chat_history.duckdb` (DuckDB)
- This is the same database used for chat history
- Database is persisted in the `epidbot_data` Docker volume
- Backups include the user database automatically

## Related Documentation

- [SCALING.md](../SCALING.md) - Infrastructure scaling guide
- [README.md](../README.md) - Main documentation
- [ansible/roles/epidbot/](../../ansible/roles/epidbot/) - Ansible role
