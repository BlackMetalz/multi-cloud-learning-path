# --- Step 5: Lifecycle Management Policy ---
# Chạy 1 lần / 24h. Không trigger ngay — đừng kỳ vọng instant.

resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  # Rule 1: logs/ → cool sau 30d, archive sau 90d, delete sau 365d
  rule {
    name    = "logs-tier-down"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }

      # Snapshots (tạo bằng versioning) cleanup
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }

      # Old versions delete
      version {
        delete_after_days_since_creation = 90
      }
    }
  }

  # Rule 2: public-static/ → no transition (web assets stay hot)
  rule {
    name    = "public-keep-hot"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["public-static/"]
    }

    actions {
      base_blob {
        # No tier-down, no delete. Chỉ purge old versions để không tốn $.
        delete_after_days_since_modification_greater_than = 730
      }
      version {
        delete_after_days_since_creation = 30
      }
    }
  }
}
