# Seed mock data into Frappe Cloud via REST API
# Uses token auth — no password needed

$base = "https://najod.k.frappe.cloud"
$auth = "token 0e961d779b3ae8e:de7aae198bb57bf"
$headers = @{
    "Authorization" = $auth
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
}

function Post-Doc($doctype, $body) {
    $json = $body | ConvertTo-Json -Depth 10
    $url  = "$base/api/resource/$doctype"
    try {
        $r = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $json
        Write-Host "  ✓ Created $doctype : $($r.data.name)"
        return $r.data.name
    } catch {
        Write-Host "  ✗ $doctype failed: $($_.Exception.Message)"
        return $null
    }
}

function Submit-Doc($doctype, $name) {
    $url  = "$base/api/resource/$doctype/$name"
    $json = '{"docstatus":1}'
    try {
        $r = Invoke-RestMethod -Uri $url -Method PUT -Headers $headers -Body $json
        Write-Host "  ✓ Submitted $doctype : $name"
    } catch {
        Write-Host "  ✗ Submit $name failed: $($_.Exception.Message)"
    }
}

# ── 1. Item Group ──────────────────────────────────────────────────────────
Write-Host "`n── Creating Item Group..."
Post-Doc "Item Group" @{
    item_group_name = "Services"
    parent_item_group = "All Item Groups"
    is_group = 0
} | Out-Null

# ── 2. Items ───────────────────────────────────────────────────────────────
Write-Host "`n── Creating Items..."
$items = @(
    @{ item_code="WEB-DEV"; item_name="Web Development Service"; item_group="Services"; stock_uom="Nos" },
    @{ item_code="ERP-IMPL"; item_name="ERP Implementation"; item_group="Services"; stock_uom="Nos" },
    @{ item_code="MOB-APP"; item_name="Mobile App Development"; item_group="Services"; stock_uom="Nos" },
    @{ item_code="CONSULT"; item_name="IT Consulting"; item_group="Services"; stock_uom="Hour" },
    @{ item_code="SUPPORT"; item_name="Technical Support"; item_group="Services"; stock_uom="Hour" }
)
foreach ($item in $items) { Post-Doc "Item" $item | Out-Null }

# ── 3. Customers ───────────────────────────────────────────────────────────
Write-Host "`n── Creating Customers..."
$customers = @(
    @{ customer_name="Acacia Supermarket"; customer_type="Company"; customer_group="Commercial" },
    @{ customer_name="Pearl Engineering Ltd"; customer_type="Company"; customer_group="Commercial" },
    @{ customer_name="Nile Breweries Ltd"; customer_type="Company"; customer_group="Commercial" },
    @{ customer_name="Kampala Hardware Store"; customer_type="Company"; customer_group="Commercial" },
    @{ customer_name="Sarah Namukasa"; customer_type="Individual"; customer_group="Individual" }
)
$customerNames = @()
foreach ($c in $customers) {
    $n = Post-Doc "Customer" $c
    if ($n) { $customerNames += $n }
}

# ── 4. Sales Invoices ──────────────────────────────────────────────────────
Write-Host "`n── Creating & Submitting Sales Invoices..."
$today = Get-Date -Format "yyyy-MM-dd"
$invoiceData = @(
    @{ customer="Acacia Supermarket"; item="ERP-IMPL"; qty=1; rate=2500000; date=(Get-Date).AddDays(-2).ToString("yyyy-MM-dd") },
    @{ customer="Pearl Engineering Ltd"; item="WEB-DEV"; qty=1; rate=1800000; date=(Get-Date).AddDays(-4).ToString("yyyy-MM-dd") },
    @{ customer="Nile Breweries Ltd"; item="MOB-APP"; qty=1; rate=3200000; date=(Get-Date).AddDays(-1).ToString("yyyy-MM-dd") },
    @{ customer="Kampala Hardware Store"; item="CONSULT"; qty=8; rate=150000; date=(Get-Date).AddDays(-3).ToString("yyyy-MM-dd") },
    @{ customer="Sarah Namukasa"; item="SUPPORT"; qty=5; rate=80000; date=(Get-Date).AddDays(-5).ToString("yyyy-MM-dd") },
    @{ customer="Acacia Supermarket"; item="SUPPORT"; qty=10; rate=80000; date=(Get-Date).AddDays(-6).ToString("yyyy-MM-dd") },
    @{ customer="Pearl Engineering Ltd"; item="CONSULT"; qty=4; rate=150000; date=$today }
)

foreach ($inv in $invoiceData) {
    $body = @{
        customer     = $inv.customer
        posting_date = $inv.date
        due_date     = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
        items        = @(
            @{
                item_code = $inv.item
                qty       = $inv.qty
                rate      = $inv.rate
            }
        )
    }
    $name = Post-Doc "Sales Invoice" $body
    if ($name) { Submit-Doc "Sales Invoice" $name }
}

# ── 5. Payment Entries ─────────────────────────────────────────────────────
Write-Host "`n── Creating & Submitting Payment Entries..."
$payments = @(
    @{ party="Acacia Supermarket"; amount=2500000; date=(Get-Date).AddDays(-1).ToString("yyyy-MM-dd"); type="Receive" },
    @{ party="Pearl Engineering Ltd"; amount=1800000; date=(Get-Date).AddDays(-3).ToString("yyyy-MM-dd"); type="Receive" },
    @{ party="Nile Breweries Ltd"; amount=1500000; date=$today; type="Receive" },
    @{ party="Kampala Hardware Store"; amount=320000; date=(Get-Date).AddDays(-2).ToString("yyyy-MM-dd"); type="Receive" }
)

foreach ($p in $payments) {
    $body = @{
        payment_type        = $p.type
        party_type          = "Customer"
        party               = $p.party
        paid_from           = "Debtors - T"
        paid_to             = "Cash - T"
        paid_amount         = $p.amount
        received_amount     = $p.amount
        posting_date        = $p.date
    }
    $name = Post-Doc "Payment Entry" $body
    if ($name) { Submit-Doc "Payment Entry" $name }
}

Write-Host "`n✅ Seed data complete! Refresh the Flutter app to see live data."
