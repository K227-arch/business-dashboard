import sys
sys.path.insert(0, '/home/frappe/frappe-bench/apps/frappe')
sys.path.insert(0, '/home/frappe/frappe-bench/apps/erpnext')

import frappe

frappe.init(site='localhost', sites_path='/home/frappe/frappe-bench/sites')
frappe.connect()

# Generate API key and secret
api_key = frappe.generate_hash(length=15)
api_secret = frappe.generate_hash(length=15)

# Update Administrator user  
frappe.db.set_value('User', 'Administrator', 'api_key', api_key)
frappe.db.set_value('User', 'Administrator', 'api_secret', api_secret)
frappe.db.commit()

print('API_KEY=' + api_key)
print('API_SECRET=' + api_secret)
