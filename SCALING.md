# Scaling Guide for kwar-ai Infrastructure

This guide covers scaling strategies and cost projections for the kwar-ai infrastructure on Hetzner Cloud.

## Current Configuration

| Component | Specification | Monthly Cost |
|-----------|---------------|--------------|
| **Server** | CX43 (8 vCPU, 16GB RAM) | €17 |
| **PostgreSQL Volume** | 50 GB | €2.50 |
| **Libby Volume** | 20 GB | €1.00 |
| **EpidBot Volume** | 20 GB | €1.00 |
| **Backup Volume** | 100 GB | €5.00 |
| **Monitoring Volume** | 10 GB | €0.50 |
| **Traffic** | 20 TB included | €0 |
| **Total** | | **~€27/mo** |

---

## Vertical Scaling (Scale Up)

### Compute Options

#### Shared vCPU (Best Value)

| Server Type | vCPU | RAM | SSD | Price | Use Case |
|-------------|------|-----|-----|-------|----------|
| cx23 | 2 | 4 GB | 40 GB | €4/mo | Development/testing |
| cpx21 | 3 | 4 GB | 80 GB | €9/mo | Small workloads |
| cpx31 | 4 | 8 GB | 160 GB | €15/mo | Light production |
| **cx43** | **8** | **16 GB** | **160 GB** | **€17/mo** | **Current (recommended)** |
| cpx51 | 16 | 32 GB | 360 GB | €54/mo | Scale-up option |

#### Dedicated vCPU (Consistent Performance)

| Server Type | vCPU | RAM | SSD | Price | Use Case |
|-------------|------|-----|-----|-------|----------|
| ccx13 | 2 | 8 GB | 80 GB | €15/mo | CPU-intensive small |
| ccx23 | 4 | 16 GB | 160 GB | €30/mo | Production workloads |
| ccx33 | 8 | 32 GB | 240 GB | €60/mo | High-traffic production |
| ccx43 | 16 | 64 GB | 360 GB | €120/mo | Large-scale production |
| ccx53 | 32 | 128 GB | 600 GB | €240/mo | Enterprise workloads |
| ccx63 | 48 | 192 GB | 960 GB | €480/mo | Maximum capacity |

### How to Scale Vertically

1. **Edit `terraform.tfvars`:**
   ```hcl
   server_type = "ccx33"  # Upgrade to 8 vCPU dedicated
   ```

2. **Apply the change:**
   ```bash
   tofu apply
   ```

3. **Note:** Server will be recreated (downtime ~2-5 minutes)

---

## Storage Scaling

### Block Storage Pricing

| Size | Monthly Cost |
|------|-------------|
| 10 GB | €0.50 |
| 50 GB | €2.50 |
| 100 GB | €5.00 |
| 200 GB | €10.00 |
| 500 GB | €25.00 |
| 1 TB | €50.00 |
| 5 TB | €250.00 |
| 10 TB | €500.00 |

**Rate:** €0.05/GB/month

### How to Scale Storage

1. **Edit `terraform.tfvars`:**
   ```hcl
   postgres_volume_size = 100  # Increase from 50GB to 100GB
   ```

2. **Apply and resize filesystem:**
   ```bash
   tofu apply
   ./scripts/resize-volumes.sh  # If needed
   ```

### Volume Limits

- Maximum volume size: 10 TB
- Maximum volumes per server: 16
- Total attachable storage: 160 TB per server

---

## Horizontal Scaling (Scale Out)

### Option 1: Load Balancer + Multiple Servers

```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │   (€6/mo)       │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
              ▼              ▼              ▼
        ┌──────────┐  ┌──────────┐  ┌──────────┐
        │ Server 1 │  │ Server 2 │  │ Server 3 │
        │ (CX43)   │  │ (CX43)   │  │ (CX43)   │
        │ €17/mo   │  │ €17/mo   │  │ €17/mo   │
        └──────────┘  └──────────┘  └──────────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────┴────────┐
                    │ Shared Postgres │
                    │ (Managed or     │
                    │  separate node) │
                    └─────────────────┘
```

**Estimated Cost:** €6 + (3 × €17) + shared storage ≈ €70-100/mo

### Option 2: Separate Services

```
┌──────────────────┐     ┌──────────────────┐
│   EpidBot Node   │     │   Libby Node     │
│   (CX43 - €17)   │     │   (CCX23 - €30)  │
│   Gradio App     │     │   Ollama + API   │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         └──────────┬─────────────┘
                    │
         ┌──────────┴──────────┐
         │  PostgreSQL Node    │
         │  (CCX13 - €15)      │
         │  + 100GB volume     │
         └─────────────────────┘
```

**Estimated Cost:** €17 + €30 + €15 + storage ≈ €70-80/mo

---

## Cost Projections

### Scenario 1: Current Setup (Small)

```
Server: CX43 (8vCPU/16GB)       €17
Storage: 200GB total            €10
Traffic: <20TB                  €0
────────────────────────────────────
TOTAL:                          €27/mo (~$30)
```

### Scenario 2: Production (Medium)

```
Server: CCX33 (8vCPU/32GB)      €60
Storage: 500GB total            €25
Traffic: <20TB                  €0
────────────────────────────────────
TOTAL:                          €85/mo (~$95)
```

### Scenario 3: High Traffic (Large)

```
Server: CCX43 (16vCPU/64GB)     €120
Storage: 1TB total              €50
Load Balancer                   €6
Traffic: 25TB (5TB over)        €5
────────────────────────────────────
TOTAL:                          €181/mo (~$200)
```

### Scenario 4: Enterprise (Very Large)

```
3x Server: CCX43                €360
Load Balancer                   €6
Storage: 5TB total              €250
Traffic: 50TB (30TB over)       €30
────────────────────────────────────
TOTAL:                          €646/mo (~$710)
```

---

## Traffic/Bandwidth

### Included Traffic by Location

| Location | Included Traffic | Overage Rate |
|----------|-----------------|--------------|
| EU (nbg1, fsn1, hel1) | **20 TB/month** | €1/TB |
| US (ash, hil) | 1 TB/month | €1/TB |
| Singapore (sin) | 0.5 TB/month | €1.43/TB |

**Recommendation:** Use EU locations for best bandwidth value.

### Traffic Cost Examples

| Monthly Traffic | EU Cost | US Cost |
|-----------------|---------|---------|
| 10 TB | €0 | €9 |
| 20 TB | €0 | €19 |
| 30 TB | €10 | €29 |
| 50 TB | €30 | €49 |
| 100 TB | €80 | €99 |

---

## Object Storage (S3-Compatible)

For large datasets, backups, and static files.

### Pricing

| Resource | Price |
|----------|-------|
| Base price | €5/mo (includes 1TB storage + 1TB egress) |
| Additional storage | €0.0067/TB-hour (~€5/TB/month) |
| Additional egress | €1/TB |

### Use Cases

- **Backup archives:** Move old backups from block storage to object storage
- **Large datasets:** PySUS data files
- **Static assets:** Generated plots and reports
- **Disaster recovery:** Off-site backup copies

### Implementation

```hcl
# Future: Add to main.tf for object storage support
# resource "hcloud_object_storage_bucket" "backups" {
#   name = "kwar-ai-backups"
#   location = "fsn1"
# }
```

---

## Scaling Decision Matrix

| Symptom | Solution | Action |
|---------|----------|--------|
| High CPU usage (>80%) | Scale up CPU | Change `server_type` to larger instance |
| High memory usage (>90%) | Scale up RAM | Change `server_type` to higher memory tier |
| Disk space warning | Scale storage | Increase `*_volume_size` variables |
| Slow database queries | Scale PostgreSQL | Increase `postgres_volume_size` or dedicated instance |
| Slow model inference | Scale Ollama | Increase `libby_volume_size` or dedicated GPU |
| High traffic (>20TB) | Stay in EU | Use `hel1`, `nbg1`, or `fsn1` locations |
| Need high availability | Horizontal scale | Add Load Balancer + multiple servers |

---

## Monitoring Scaling Metrics

Key metrics to watch (available in Grafana):

1. **CPU Usage:** `rate(container_cpu_usage_seconds_total[5m])`
2. **Memory Usage:** `container_memory_usage_bytes`
3. **Disk Usage:** `node_filesystem_avail_bytes`
4. **Network Traffic:** `rate(node_network_receive_bytes_total[5m])`

### Alerts

Set alerts at:
- CPU > 80% for 5 minutes → Consider scaling
- Memory > 90% for 5 minutes → Scale immediately
- Disk > 80% → Increase volume size
- Traffic approaching 20TB → Monitor closely

---

## Quick Reference Commands

```bash
# Check current server type
tofu output server_type

# Scale up server (WARNING: causes downtime)
tofu apply -var="server_type=ccx33"

# Scale storage
tofu apply -var="postgres_volume_size=100"

# Check costs
tofu output monthly_cost_estimate

# View all outputs
tofu output
```

---

## Cost Optimization Tips

1. **Use EU locations** for 20TB free traffic
2. **Start with shared vCPU** (CX/CPX series), upgrade to dedicated (CCX) only if needed
3. **Monitor actual usage** before scaling
4. **Use Object Storage** for cold data and archives
5. **Clean up old backups** automatically (already configured)
6. **Right-size volumes** - don't over-provision storage

---

## Next Steps

1. Monitor current resource usage in Grafana
2. Set up alerts for scaling thresholds
3. Plan scaling path based on growth projections
4. Consider Object Storage for long-term data retention
5. Evaluate horizontal scaling when approaching CCX63 limits
